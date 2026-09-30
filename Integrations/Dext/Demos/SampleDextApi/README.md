# Sample API with Dext

Console application that publishes a pet store API written with Dext and documented with SwagDoc.

## Dependencies

The project expects Dext in the library path of the IDE, which is where TMS Smart Setup and the packages of Dext
install it. The source of SwagDoc and of the middleware are already in the search path, as relative folders of
this repository.

## Running

Build and run the project. The console shows the addresses published by the application:

```
The sample API is running on http://localhost:9000
Documentation: http://localhost:9000/docs
Document: http://localhost:9000/docs/openapi.json
Swagger support of Dext: http://localhost:9000/swagger
```

The parameters below change what is published, and they can be combined:

| Parameter   | Effect                                                                                  |
| ----------- | --------------------------------------------------------------------------------------- |
| `-scalar`   | Renders the document with Scalar instead of Swagger UI                                   |
| `-swagger2` | Publishes a Swagger 2.0 document at `/docs/swagger.json` instead of an OpenAPI 3 one     |
| `-www`      | Loads the files of the interface from the `www` folder next to the executable            |

For `-www`, copy `swagger-ui.css`, `swagger-ui-bundle.js` and `swagger-ui-standalone-preset.js` from
`Deploy\OpenApi3` to `www\swagger-ui`, and `standalone.js` from `Deploy\OpenApi3-Scalar` to `www\scalar`, both
next to the executable.

The project does not declare the conditional defines that embed the files of the interfaces, so without `-www`
the page loads them from a public CDN. Declare `DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI` or
`DEXT_SWAGDOC_EMBEDDED_SCALAR` in the options of the project, under *Conditional defines*, to publish them from
the executable itself.

## What the sample shows

- `Sample.Dext.Pets.pas` registers four Minimal API endpoints and describes them with the fluent API of Dext:
  summaries, tags, a request type, responses with types and a security scheme. The HEAD endpoint, which the
  Swagger support of Dext does not write, is also documented.
- `Sample.Dext.Orders.pas` is a controller described with the attributes of Dext, including `[Authorize]` and
  `[AllowAnonymous]`.
- `Sample.Dext.Models.pas` describes the types with the Swagger attributes of Dext and, where Dext has no
  attribute for it, with `SwagLength` and `SwagRange` of SwagDoc.
- `SampleDextApi.dpr` configures the serializer of Dext with camelCase names and enumerations by name, and the
  document follows it. It calls `TDextSwagDoc.Use` before the endpoints are registered, and the `/health`
  endpoint, registered last and without any description, is documented as well.
- `TSamplePetsApi.DocumentApi` completes what Dext does not keep, the type of the path parameter, with
  `SwagDocApi.Route`.
- The Swagger support of Dext is published at `/swagger`, so both documents can be compared.
