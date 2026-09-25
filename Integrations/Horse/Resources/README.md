# Distribution files of the user interfaces

The files below are embedded in the application when the conditional define of the interface is declared, so
the documentation is published without depending on an external address. They are stored compressed with gzip
and decompressed once, on the first request of each file.

| Resource                       | File                                 | Origin                                                |
| ------------------------------ | ------------------------------------ | ----------------------------------------------------- |
| `SWAGDOC_SWAGGER_UI_CSS`       | `swagger-ui.css.gz`                  | swagger-ui-dist 5.32.15                               |
| `SWAGDOC_SWAGGER_UI_BUNDLE_JS` | `swagger-ui-bundle.js.gz`            | swagger-ui-dist 5.32.15                               |
| `SWAGDOC_SWAGGER_UI_PRESET_JS` | `swagger-ui-standalone-preset.js.gz` | swagger-ui-dist 5.32.15                               |
| `SWAGDOC_SCALAR_STANDALONE_JS` | `standalone.js.gz`                   | @scalar/api-reference 1.68.0, dist/browser            |

Declaring `HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI` adds about 510 KB to the executable and
`HORSE_SWAGDOC_EMBEDDED_SCALAR` about 1 MB.

## Licenses

- Swagger UI is distributed by SmartBear Software under the Apache License 2.0, in the `swagger-ui.LICENSE.txt`
  and `swagger-ui.NOTICE.txt` files.
- Scalar is distributed under the MIT License, in the `scalar.LICENSE.txt` file.

Applications that embed the files must keep these notices with their distribution.

## Updating the files

Download the new release, compress each file with gzip and compile the resources again:

```sh
curl -o swagger-ui.css https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css
curl -o swagger-ui-bundle.js https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js
curl -o swagger-ui-standalone-preset.js https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-standalone-preset.js
curl -o standalone.js https://cdn.jsdelivr.net/npm/@scalar/api-reference/dist/browser/standalone.js
gzip -9 swagger-ui.css swagger-ui-bundle.js swagger-ui-standalone-preset.js standalone.js
brcc32 Horse.SwagDoc.SwaggerUI.rc -foHorse.SwagDoc.SwaggerUI.res
brcc32 Horse.SwagDoc.Scalar.rc -foHorse.SwagDoc.Scalar.res
```

The version written in the table above and the address of the CDN declared in the `Horse.SwagDoc.Config` unit
must be reviewed when the files are updated.
