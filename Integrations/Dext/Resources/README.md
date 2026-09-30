# Distribution files of the user interfaces

The files below are embedded in the application when the conditional define of the interface is declared, so
the documentation is published without depending on an external address. They are stored compressed with gzip
and decompressed once, on the first request of each file.

| Resource                            | File                                 | Origin                                     |
| ----------------------------------- | ------------------------------------ | ------------------------------------------ |
| `DEXT_SWAGDOC_SWAGGER_UI_CSS`       | `swagger-ui.css.gz`                  | swagger-ui-dist 5.32.15                    |
| `DEXT_SWAGDOC_SWAGGER_UI_BUNDLE_JS` | `swagger-ui-bundle.js.gz`            | swagger-ui-dist 5.32.15                    |
| `DEXT_SWAGDOC_SWAGGER_UI_PRESET_JS` | `swagger-ui-standalone-preset.js.gz` | swagger-ui-dist 5.32.15                    |
| `DEXT_SWAGDOC_SCALAR_STANDALONE_JS` | `standalone.js.gz`                   | @scalar/api-reference 1.72.1, dist/browser |

Declaring `DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI` adds about 510 KB to the executable and
`DEXT_SWAGDOC_EMBEDDED_SCALAR` about 1.2 MB.

The resource names differ from the ones of the Horse integration, so an application can link both without a
duplicate resource.

## Licenses

- Swagger UI is distributed by SmartBear Software under the Apache License 2.0, in the `swagger-ui.LICENSE.txt`
  and `swagger-ui.NOTICE.txt` files.
- Scalar is distributed under the MIT License, in the `scalar.LICENSE.txt` file.

Applications that embed the files must keep these notices with their distribution.

## Updating the files

The files are the same ones published in the `Deploy/OpenApi3` and `Deploy/OpenApi3-Scalar` folders. Download
the new release, compress each file with gzip and compile the resources again:

```sh
curl -o swagger-ui.css https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css
curl -o swagger-ui-bundle.js https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js
curl -o swagger-ui-standalone-preset.js https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-standalone-preset.js
curl -o standalone.js https://cdn.jsdelivr.net/npm/@scalar/api-reference/dist/browser/standalone.js
gzip -9 -n swagger-ui.css swagger-ui-bundle.js swagger-ui-standalone-preset.js standalone.js
brcc32 Dext.SwagDoc.SwaggerUI.rc -foDext.SwagDoc.SwaggerUI.res
brcc32 Dext.SwagDoc.Scalar.rc -foDext.SwagDoc.Scalar.res
```

The version written in the table above and the address of the CDN declared in the `Dext.SwagDoc.Config` unit
must be reviewed when the files are updated.
