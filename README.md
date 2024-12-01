# :warning: this project is not maintained anymore :warning:



# ddev-db-mssql <!-- omit in toc -->

* [What is ddev-db-mssql?](#what-is-ddev-db-mssql)
* [Thanks to](#thanks-to)
* [Components of the repository](#components-of-the-repository)
* [Getting started](#getting-started)

## What is ddev-db-mssql?

This repository provide [DDEV](https://ddev.readthedocs.io) add-on for a Microsoft SQL Server 2019 db.

In DDEV addons can be installed from the command line.

For DDEV v1.23.5 or above run

```sh
ddev add-on get ddev/ddev-db-mssql
```

For earlier versions of DDEV run

```sh
ddev get ddev/ddev-db-mssql
```

## Thanks to

* this discussion for a good base configuration [How to install the SQL Server PHP drivers in DDEV-Local](https://stackoverflow.com/questions/58086933/how-to-install-the-sql-server-php-drivers-in-ddev-local)
* this discussion for fix of sqlsrv and pdo_sqlsrv in php [Error when installing sqlsrv and pdo_sqlsrv in php8+ apache docker image #1438](https://github.com/microsoft/msphpsql/issues/1438)

## Components of the repository

this repo provide a:
* [docker-compose.db-mssql.yaml](docker-compose.db-mssql.yaml) service based on `mcr.microsoft.com/mssql/server:2019-latest`
* web-build updated configuration adding `sqlsrv` and `pdo_sqlsrv` to the default PHP config (see [Dockerfile.mssql](web-build/Dockerfile.mssql) and [install_sqlsrv.sh](web-build/install_sqlsrv.sh))

## Getting started

1. add the add-on to your [DDEV](https://ddev.readthedocs.io) project using `ddev add-on get ddev/ddev-db-mssql` (or `ddev get ddev/ddev-db-mssql` for older versions of DDEV)
2. restart with `ddev restart`
3. please wait for the build of the updated `web-build`
4. add a simple test PHP like the MS provided for [Testing Your Installation](https://learn.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac?view=sql-server-ver16) replacing the `${DDEV_SITENAME}` from your project
5. add `omit_containers: [db]` to your [.ddev/install.yaml](.ddev/install.yaml) to omit the default db instance

```php
<?php
$serverName = "ddev-DDEV_SITENAME-db-mssql"; # ddev-${DDEV_SITENAME}-db-mssql
$connectionOptions = array(
    "database" => "master",
    "uid" => "sa",
    "pwd" => "belloQuesto100",
    "Encrypt" => false,
    "TrustServerCertificate"=>false
);

function exception_handler($exception) {
    echo "<h1>Failure</h1>";
    echo "Uncaught exception: " , $exception->getMessage();
    echo "<h1>PHP Info for troubleshooting</h1>";
    phpinfo();
}

set_exception_handler('exception_handler');

// Establishes the connection
$conn = sqlsrv_connect($serverName, $connectionOptions);
if ($conn === false) {
    die(formatErrors(sqlsrv_errors()));
}

// Select Query
$tsql = "SELECT @@Version AS SQL_VERSION";

// Executes the query
$stmt = sqlsrv_query($conn, $tsql);

// Error handling
if ($stmt === false) {
    die(formatErrors(sqlsrv_errors()));
}
?>

<h1> Success Results : </h1>

<?php
while ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
    echo $row['SQL_VERSION'] . PHP_EOL;
}

sqlsrv_free_stmt($stmt);
sqlsrv_close($conn);

function formatErrors($errors)
{
    // Display errors
    echo "<h1>SQL Error:</h1>";
    echo "Error information: <br/>";
    foreach ($errors as $error) {
        echo "SQLSTATE: ". $error['SQLSTATE'] . "<br/>";
        echo "Code: ". $error['code'] . "<br/>";
        echo "Message: ". $error['message'] . "<br/>";
    }
}
?>
```

**Contributed and maintained by [@CONTRIBUTOR](https://github.com/CONTRIBUTOR) based on the original [ddev-contrib recipe](https://github.com/ddev/ddev-contrib/tree/master/docker-compose-services/RECIPE) by [@CONTRIBUTOR](https://github.com/CONTRIBUTOR)**

**Originally Contributed by [somebody](https://github.com/somebody) in <https://github.com/ddev/ddev-contrib/>
