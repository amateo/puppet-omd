define omd::site::nbp::node (
  $site,
  $target,
  $label,
  $function = 'worst()',
  $id       = undef,
) {

  include ::omd::site::nbp::setup

  $nbpdir = $omd::site::nbp::setup::nbpdir
  $safe_target_name = regsubst("${site}_${target}", '[/:\n]', '_', 'GM')
  $node_file = "${nbpdir}/${safe_target_name}.yaml"

  $_id = $id ? {
    undef   => $name,
    default => $label,
  }

  yaml_setting {"nbp::node::${name}::function":
    target => $node_file,
    key    => "nodes/${name}/function",
    value  => $function,
  }

  yaml_setting {"nbp::node::${name}::label":
    target => $node_file,
    key    => "nodes/${name}/label",
    value  => $label,
  }

  yaml_setting {"nbp::node::${name}::id":
    target => $node_file,
    key    => "nodes/${name}/id",
    value  => $_id,
  }
}
