{
  deploy = (builtins.getFlake (toString ../..)).lib.deploy;
}
