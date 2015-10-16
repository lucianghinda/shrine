class Shrine
  module Plugins
    # The dynamic_storage plugin allows you to register a storage using a
    # regex, and evaluate the storage class dynamically depending on the regex.
    #
    # Example:
    #
    #     plugin :dynamic_storage
    #
    #     storage /store_(\w+)/ do |match|
    #       Shrine::Storages::S3.new(bucket: match[1])
    #     end
    #
    # The above example uses S3 storage where the bucket name depends on the
    # storage name suffix. For example, `:store_foo` will use S3 storage which
    # saves files to the bucket "foo".
    #
    # This can be useful in combination with the default_storage plugin.
    module DynamicStorage
      module ClassMethods
        def dynamic_storages
          @dynamic_storages ||= {}
        end

        def storage(regex, &block)
          dynamic_storages[regex] = block
        end

        def find_storage(name)
          resolve_dynamic_storage(name) or super
        end

        private

        def resolve_dynamic_storage(name)
          dynamic_storage_cache.fetch(name) do
            dynamic_storages.each do |regex, block|
              if match = name.to_s.match(regex)
                dynamic_storage_cache[name] = block.call(match)
                break
              end
            end

            dynamic_storage_cache[name]
          end
        end

        def dynamic_storage_cache
          @dynamic_storage_cache ||= {}
        end
      end
    end

    register_plugin(:dynamic_storage, DynamicStorage)
  end
end
