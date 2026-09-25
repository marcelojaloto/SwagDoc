# Sample API with Horse

Console application that publishes a pet store API written with Horse and documented with SwagDoc.

## Dependencies

The project expects Horse in the `modules\horse\src` folder, which is where the
[Boss](https://github.com/HashLoad/boss) package manager installs it:

```
boss install
```

Another copy of Horse can be used by replacing `modules\horse\src` in the search path of the project.
The source of SwagDoc and of the middleware are already in the search path, as relative folders of this
repository.

## Running

Build and run the project. The console shows the addresses published by the application:

```
The sample API is running on http://localhost:9000
Documentation: http://localhost:9000/docs
Document: http://localhost:9000/docs/openapi.json
```

Run it with the `-scalar` parameter to render the document with Scalar instead of Swagger UI:

```
SampleHorseApi.exe -scalar
```

The project does not declare the conditional defines that embed the files of the interfaces, so the page loads
them from a public CDN. Declare `HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI` or `HORSE_SWAGDOC_EMBEDDED_SCALAR` in the
options of the project, under *Conditional defines*, to publish them from the executable itself.

## What the sample shows

- `Sample.Api.Pets.pas` registers three routes in Horse and documents them with the objects of SwagDoc: a tag,
  a schema of the components, a request body, responses with media types and a path parameter declared by the
  route `/pets/:id`.
- The `/health` route is registered in `SampleHorseApi.dpr` and is not documented by the application, so it is
  written in the document by the discovery of the registered routes.
- `SampleHorseApi.dpr` selects the user interface at runtime, which is what the `UserInterface` setting does.
