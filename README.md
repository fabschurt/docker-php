# Docker PHP-FPM 7.3

This image derives from the [official PHP-FPM 7.3 image](https://hub.docker.com/_/php),
extending it with a standardized bootstrap workflow:

* install Composer, [hirak/prestissimo](https://packagist.org/packages/hirak/prestissimo)
  (to speed up Composer installs) and some commonly-used system libraries
* install/enable some commonly-used PHP extensions
* create a default unprivileged runtime user
* create a default runtime working directory owned by the aforementioned runtime
  user and `COPY` the codebase into it
* automatically install Composer dependencies if a `composer.json` file is found
  at the project’s root

Note that this is mainly an ONBUILD-based image, to allow for customization of
the build args used in the bootstrap process while still making inheritance
possible. So, rather than using this image as is, you should actually extend
`FROM` it (otherwise you won’t be able to customize its build args):

```
FROM fabschurt/php

# …
```

The following build args are available:

* `ENVIRONMENT`: the «stage» which your project currently runs under; expected
  values are `dev`, `test`, `staging` or `prod` (default: `prod`); the value of
  this variable will be used as the default value for the `ENVIRONMENT` env var,
  and will also determine minor stuff like which base `php.ini` config file to
  use and what command-line options will be used for the initial `composer install`
* `LOCAL_PROJECT_ROOT`: the path (relative to the build context) of the
  directory where your codebase resides, in order to `COPY` it into the image
  at build time (default: `.`, the current directory)
* `WORKING_DIRECTORY`: the path of the default working directory in the image,
  where the codebase will be copied to; it does not have to exist beforehand
  (default: `/usr/src/app`)
* `RUNTIME_USER_NAME`: the name of the default runtime user that will be created
  in order to run the project’s code (default: `php`)
* `RUNTIME_USER_UID`: the Linux user ID of the default runtime user (default:
  `1000`)

Lastly, if you want to add some custom PHP config, you can just copy you own
config file(s) into the image:

```
COPY path/to/your/local/php.ini "${PHP_INI_DIR}/conf.d/"
```

## License

This software package is licensed under the [MIT License](https://opensource.org/licenses/MIT).
