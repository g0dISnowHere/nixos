{
  operator = {
    alias = "djoolz";
    recipients =
      [ "age10k89krww75k7jp09atly6xay636673nwy66kwv5s3epupf4zl3lser84gy" ];
  };

  hosts = {
    albaldah = {
      recipient =
        "age1hl3u09qjx5mz5939agcjpr8u0wecsu8vqcqn38ykeq2qswp6s4eqlhz9cq";
      class = "homelab";
    };
    alhena = {
      recipient =
        "age1089ktlqhw7fh82pps74m8upuxp2m2ljzl73ya9ujtyr8s8nf8e6s2u5gvh";
      class = "workstation";
    };
    centauri = {
      recipient =
        "age1hus8yrj5y6aa0fntqp8glv7pqxqnhczt8y0xhaxznxvk6e2s4vls5v2dcc";
      class = "workstation";
    };
    mirach = {
      recipient =
        "age1d860j0aa5d2fru0rfpyp4mxtyzwt6fw8crvlzerw542gqtfnnd3qfprgw2";
      class = "workstation";
    };
  };

  scopes = {
    users = {
      djoolz = { hosts = [ "albaldah" "alhena" "centauri" "mirach" ]; };
    };

    services = {
      fleet-test = { hosts = [ "albaldah" "alhena" "centauri" "mirach" ]; };
    };
  };
}
