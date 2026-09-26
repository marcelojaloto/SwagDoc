# SwagDoc and DelphiMVCFramework

[DelphiMVCFramework](https://github.com/danieleteti/delphimvcframework) documents an API with SwagDoc, and the
integration between them is written on the framework side, not here. This folder describes how the two work
together, what the coupling means for an application and how to publish an OpenAPI 3 document.

## The coupling is a copy inside the framework

The middleware for Horse is distributed by SwagDoc, in the `Integrations/Horse` folder, and an application adds
SwagDoc to its own dependencies. DelphiMVCFramework works the other way around: **the sources of SwagDoc are
bundled in the tree of the framework**, in `lib/swagdoc`, and the middleware that uses them,
`MVCFramework.Middleware.Swagger`, belongs to the framework.

```
delphimvcframework/
  sources/
    MVCFramework.Middleware.Swagger.pas   the middleware that publishes the document
    MVCFramework.Swagger.Commons.pas      the attributes and the reading of the controllers
  lib/
    swagdoc/Source/                       the copy of SwagDoc used by the middleware
```

Three consequences follow from that:

- An application does not install SwagDoc. It adds `lib/swagdoc/Source` to the search path of the project,
  together with the other folders of the framework, and the units are compiled into the executable.
- The release of SwagDoc that documents the API is **the one bundled with the version of the framework**. An
  application that needs a newer release replaces the content of `lib/swagdoc` in its copy of the framework.
- What the document can express is limited by what the middleware writes, because the application does not
  build the document itself.

## How the document is produced

The application adds the middleware to the engine, with the information of the API and the route where the
document is published:

```delphi
FMVC.AddMiddleware(TMVCSwaggerMiddleware.Create(FMVC,
  TApiDocumentation.GetHeaderInformation('v1.0.0'),
  '/api/help/swagger.json',
  'Authentication JWT'));
```

The operations are documented with attributes on the controllers, which the middleware reads with RTTI:

```delphi
type
  [MVCPath('/customers')]
  [MVCSwagAuthentication(atJsonWebToken)]
  TCustomersController = class(TMVCController)
  public
    [MVCPath('/($id)')]
    [MVCHTTPMethod([httpGET])]
    [MVCSwagSummary('Customers', 'Returns a customer data.')]
    [MVCSwagParam(plPath, 'id', 'Customer id', ptInteger)]
    [MVCSwagResponses(200, 'Successfully returns data', TCustomer)]
    [MVCSwagResponses(404, 'Customer not found')]
    procedure GetCustomer(const id: Integer);
  end;
```

Nothing is generated while the application starts. The middleware answers the route of the document on each
request: it creates a `TSwagDoc`, walks the controllers registered in the engine, translates every attribute
into the objects of SwagDoc — a `TSwagPath` for each path, a `TSwagPathOperation` for each HTTP method, a
`TSwagDefinition` for each class used as a schema — and asks SwagDoc to write the JSON.

```delphi
LSwagDoc := TSwagDoc.Create;
try
  if fSpecVersion = ssvOpenAPI3 then
    LSwagDoc.SpecVersion := svOpenApi3;

  DocumentApiInfo(LSwagDoc);
  DocumentApiSettings(AContext, LSwagDoc);
  DocumentApiAuthentication(LSwagDoc);
  DocumentApi(LSwagDoc);

  LSwagDoc.GenerateSwaggerJson;
  InternalRender(LSwagDoc.SwaggerJson.ToJSON, AContext);
finally
  LSwagDoc.Free;
end;
```

## Publishing an OpenAPI 3 document

DelphiMVCFramework 3.5 chooses the family of the specification with the last parameter of the middleware, which
defaults to Swagger 2.0, so the document of an application that does not touch it does not change:

```delphi
FMVC.AddMiddleware(TMVCSwaggerMiddleware.Create(FMVC,
  LSwaggerInfo,
  '/api/help/swagger.json',
  'Authentication JWT',
  False,
  ssvOpenAPI3));
```

`TMVCSwaggerSpecVersion` is declared in `MVCFramework.Swagger.Commons` and has the values `ssvSwagger2` and
`ssvOpenAPI3`. The same parameter is accepted by the `Swagger` filter of `MVCFramework.Filters`, for
applications that configure the engine with filters instead of middlewares.

The attributes of the controllers do not change, and SwagDoc translates what the middleware writes in the style
of Swagger 2.0:

| Written by the middleware | Written in the document |
| --- | --- |
| `Host`, `BasePath` and `Schemes` | `servers` |
| Definitions | `components/schemas` |
| A parameter located in the body | `requestBody` with its media type |
| Security definitions | `components/securitySchemes` |
| `#/definitions/<name>` references | `#/components/schemas/<name>` references |

The authentication is the one place where the middleware itself writes something different. Swagger 2.0 has no
bearer scheme, so the token is declared as an API key sent in the `Authorization` header and the value typed in
the Authorize dialog has to include `Bearer `. In OpenAPI 3 the same token is declared as an HTTP bearer
scheme, and the dialog takes the raw token:

```json
"securitySchemes": {
  "bearer": { "type": "http", "scheme": "bearer", "bearerFormat": "JWT" }
}
```

The page that renders the document also needs to understand the family. The Swagger UI files published by an
application written years ago do not know the recent releases of the specification, and are replaced by a
current distribution, like the one in the `Deploy\OpenApi3` folder of this repository.

## Two ways to write OpenAPI 3 in DelphiMVCFramework 3.5

The framework also ships `TMVCOpenAPI3Middleware`, in `MVCFramework.Middleware.OpenAPI3`, an emitter written
from scratch over `JsonDataObjects` that writes OpenAPI 3.1 and **does not use SwagDoc**. The two middlewares
can be registered side by side, publishing the same controllers at two routes, which is what the
`swagger_primer` sample does.

| | `TMVCSwaggerMiddleware` | `TMVCOpenAPI3Middleware` |
| --- | --- | --- |
| Writes | Swagger 2.0 or OpenAPI 3.2.1, by the `ASpecVersion` parameter | OpenAPI 3.1 |
| Document built by | SwagDoc, bundled in `lib/swagdoc` | The framework itself |
| Coverage | Every attribute of the framework, JWT discovery and the CRUD documentation of `TMVCActiveRecordController` | The newer helper does not cover all of them yet |

The source of the framework states the difference plainly: the `Swagger` filter is a "full parity wrapper
around `TMVCSwaggerMiddleware`", with "features the newer OpenAPI 3 helper does not yet cover".

## Applications on an older release of the framework

An application that keeps the copy of the framework it was written for reaches OpenAPI 3 by backporting two
things into that copy: the release of SwagDoc that supports it, replacing `lib/swagdoc/Source`, and the
`ASpecVersion` parameter of the middleware. The `server-api-rest-dmvc` sample below does exactly that, over
version 3.2.0.

## Samples

Published with the framework, in https://github.com/danieleteti/delphimvcframework/tree/master/samples:

- `swagger_primer`: the smallest setup, and the one that registers the two middlewares side by side, the
  SwagDoc one at `/api/swagger.json` and the native emitter at `/api/openapi.json`.
- `swagger_doc_extended`: chooses the family at startup, with authentication, custom host and base path, and
  the attributes of the framework used in full.
- `swagger_doc`, `swagger_ui` and `swagger_api_versioning_primer`: the documentation of an API, the interface
  that renders it and the documentation of an API that publishes more than one version.

Published with SwagDoc:

- [server-api-rest-dmvc](https://github.com/marcelojaloto/Delphi/tree/master/samples/server-api-rest-dmvc): a
  customers API with JWT authentication and a PostgreSQL database, publishing an OpenAPI 3.2.1 document from a
  copy of the framework where the parameter was backported.
