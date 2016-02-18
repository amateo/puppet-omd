module Puppet_X
  module Omd
    module Thruk
      def thruk
      end

      def to_json(bp)
        json = Hash.new
        json[:rankDir] = bp[:rank_dir] if bp[:rank_dir]
        json[:state_type] = bp[:state_type] if bp[:state_type]
        json[:name] = bp[:host_name] if bp[:host_name]
        json[:template] = bp[:host_template] if bp[:host_template]
        json[:nodes] = Array.new
        # Nodo raíz
        node = {}
        node[:function] = bp[:function] if bp[:function]
        node[:label] = bp[:name]
        node[:id] = 'node1'
        node[:template] = bp[:service_template] if bp[:service_template]
        nodes = get_childs(bp)
        # Ponemos las dependencias del principal
        node[:depends] = nodes[:depends]['node1'] if nodes[:depends]['node1']
        # Añadimos el raíz a la estructura
        json[:nodes].push(node)
        # Recorremos el resto de nodes, añadiéndolos a la estructura
        nodes[:nodes].each do |n|
          n_hash = {}
          n_hash[:function] = n[:function]
          n_hash[:label] = n[:label]
          n_hash[:id] = n[:id]
          n_hash[:depends] = nodes[:depends][n[:id]] if nodes[:depends][n[:id]]
          json[:nodes].push(n_hash)
        end
        File.open(bp[:bp_target], 'w') do |f|
          f.puts JSON.pretty_generate(json)
        end
      end

      def get_childs(bp)
        nodes = Array.new
        depends = Hash.new
        Dir[bp_internal_path + '/node_*.json'].each do |f|
          json = JSON.parse(File.read(f), { :symbolize_names => true })
          if json[:site] == bp[:site] and json[:bp] == bp[:name]
            nodes.push(json)
            if depends[json[:parent]]
              depends[json[:parent]].push(json[:id])
            else
              depends[json[:parent]] = [ json[:id] ]
            end
          end
        end
        { :depends => depends, :nodes => nodes }
      end

      def get_bp_node(node)
        file = bp_internal_path + '/bp_' + node[:bp].gsub(' ', '_') + '.json'
        JSON.parse(File.read(file), { :symbolize_names => true })
      end

      def bp_internal_path
        return '/var/lib/puppet/thruk'
      end

      def get_bp_filename(name)
        bp_internal_path + '/bp_' + escape_filename(name) + '.json'
      end

      def get_node_filename(name)
        bp_internal_path + '/node_' + escape_filename(name) + '.json'
      end

      def escape_filename(name)
        filename = name.gsub(' ', '_').gsub('/', '_')
        filename
      end

    end
  end
end
