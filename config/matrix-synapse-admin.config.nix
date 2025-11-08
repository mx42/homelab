{
  tools,
  ...
}:
let
  hostname = tools.build_hostname "matrix";
in
{
  "restrictBaseUrl" = "https://${hostname}/";
}
