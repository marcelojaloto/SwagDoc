# SwagDoc and DelphiMVCFramework

[DelphiMVCFramework](https://github.com/danieleteti/delphimvcframework) documents an API with SwagDoc, and the
integration between them is written on the framework side, not here. This folder only describes how the two
work together, what the coupling means for an application and what is needed to publish an OpenAPI 3 document.

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

Three consequences follow from that, and they are the reason this page exists:

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

The information of the API is given by the application as a record, and the middleware copies it into the
document:

```delphi
Result.Title := 'Server REST API';
Result.Version := pVersion;
Result.Description := 'Server API Documentation';
Result.ContactName := 'Marcelo Jaloto';
Result.LicenseName := 'Apache License - Version 2.0, January 2004';
```

## Publishing an OpenAPI 3 document

The middleware writes a Swagger 2.0 document, because that is what the `TSwagDoc` class does when the
specification version is not defined. Two things are needed to publish an OpenAPI 3 document.

**The bundled SwagDoc must be a release that supports it**, that is, one whose `Swag.Common.Types` unit
declares `TSwagVersion`. The release bundled with the framework is replaced by the content of the `Source`
folder of this repository.

**The middleware must define the version**, right after creating the document:

```delphi
LSwagDoc := TSwagDoc.Create;
try
  LSwagDoc.SpecVersion := svOpenApi3;
  ...
```

Nothing else changes in the application. The attributes stay as they are, and SwagDoc translates what the
middleware writes in the style of Swagger 2.0:

| Written by the middleware | Written in the document |
| --- | --- |
| `Host`, `BasePath` and `Schemes` | `servers` |
| Definitions | `components/schemas` |
| A parameter located in the body | `requestBody` with its media type |
| Security definitions | `components/securitySchemes` |
| `#/definitions/<name>` references | `#/components/schemas/<name>` references |

The page that renders the document also needs to understand it. The Swagger UI files published by an
application written years ago do not know the recent releases of the specification, and are replaced by a
current distribution.

## Status

The [fork of the framework](https://github.com/marcelojaloto/delphimvcframework) already bundles the release of
SwagDoc that supports OpenAPI 3, in the `feat(swagdoc): update bundled SwagDoc with OpenAPI 3 support` commit.
The line that defines the specification version in the middleware is still missing, so the document published
by the framework is written as Swagger 2.0.

The [server-api-rest-dmvc](https://github.com/marcelojaloto/Delphi/tree/master/samples/server-api-rest-dmvc)
sample publishes an OpenAPI 3.2.1 document with the change described above applied to its copy of the
framework.
