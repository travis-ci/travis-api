module Travis::API::V3
  class ServiceIndex
    class Swagger
      LIST_PARAMS = %w[build.state build.previous_state build.event_type build.branch_name broadcast.active]

      MODEL_PROPERTIES = {
        "@href"           => { type: "string", description: "URL to retrieve the full entry"                    },
        "@representation" => { type: "string", description: "string identifying the set of attributes included" },
        "@permissions"    => {
          type:        "object",
          description: "current permissions for operations performable on object",
          additionalProperties: {
            type:        "boolean",
            description: "whether or not the current client has permission to perform the action on the object identified by the key"
          }
        },
      }

      git_user_properties = -> type {{
        name:       { type: "string", description: "#{type}'s name" },
        avatar_url: { type: "string", description: "URL to the avatar (image) of the #{type}" }
      }}

      FIELD_DEFITIONS = {
        "account.subscribed"           => { type: "boolean", description: "whether or not the account has a (paid) subscription"                 },
        "account.educational"          => { type: "boolean", description: "whether or not the account is part of the education program"          },
        "branch.name"                  => { type: "string",  description: "name of the git branch"                                               },
        "branch.default_branch"        => { type: "boolean", description: "whether or not this is the resposiotry's default branch"              },
        "branch.exists_on_github"      => { type: "boolean", description: "whether or not the branch still exists on GitHub"                     },
        "branch.last_build"            => { "$ref" => "#/defitions/build", description: "last build on the branch"                               },
        "broadcast.message"            => { type: "string",  description: "message to display to the user"                                       },
        "broadcast.created_at"         => { type: "string",  format: "dateTime", description: "when the broadcast was created"                   },
        "broadcast.active"             => { type: "boolean", description: "whether or not the brodacast should still be displayed"               },
        "broadcast.category"           => { type: "string",  description: "broadcast category (used for icon and color)"                         },
        "broadcast.recipient"          => { type: "object",  description: "either a user, organization or repository, or null for global"        }, # TODO
        "build.number"                 => { type: "string",  pattern: "\\d+", description: "incremental number for a repository's builds"        },
        "build.state"                  => { type: "string",  description: "current state of the build"                                           },
        "build.duration"               => { type: "integer",   description: "wall clock time in seconds"                                         },
        "build.event_type"             => { type: "string",  pattern: "push|pull_request|api", description: "event that triggered the build"     },
        "build.previous_state"         => { type: "string",  description: "state of the previous build (useful to see if state changed)"         },
        "build.started_at"             => { type: "string",  format: "dateTime", description: "when the build started"                           },
        "build.finished_at"            => { type: "string",  format: "dateTime", description: "when the build finished"                          },
        "build.branch"                 => { "$ref" => "#/defitions/branch", description: "the branch the build is associated with"               },
        "build.commit"                 => { "$ref" => "#/defitions/commit", description: "the commit the build is associated with"               },
        "build.jobs"                   => { "$ref" => "#/defitions/jobs", description: "list of jobs that are part of the build's matrix"        },
        "commit.sha"                   => { type: "string", description: "checksum the commit has in git and is identified by"                   },
        "commit.ref"                   => { type: "string", description: "named reference the commit has in git"                                 },
        "commit.message"               => { type: "string", description: "commit mesage"                                                         },
        "commit.compare_url"           => { type: "string", description: "URL to the commit's diff on GitHub"                                    },
        "commit.committed_at"          => { type: "string",  format: "dateTime", description: "commit date from git"                             },
        "commit.committer"             => { type: "object", description: "committer data", properties: git_user_properties["committer"]          },
        "commit.author"                => { type: "object", description: "committer data", properties: git_user_properties["author"]             },
        "job.number"                   => { type: "string",  pattern: "\\d+\\.\\d+", description: "incremental number for a repository's builds" },
        "job.state"                    => { type: "string",  description: "current state of the job"                                             },
        "job.started_at"               => { type: "string",  format: "dateTime", description: "when the job started"                             },
        "job.finished_at"              => { type: "string",  format: "dateTime", description: "when the job finished"                            },
        "job.build"                    => { "$ref" => "#/defitions/build", description: "the build the job is associated with"                   },
        "job.queue"                    => { type: "string",  description: "worker queue this job is/was scheduled on"                            },
        "job.commit"                   => { "$ref" => "#/defitions/commit", description: "the commit the job is associated with"                 },
        "owner.login"                  => { type: "string", description: "login set on GitHub"                                                   },
        "owner.name"                   => { type: "string", description: "name set on GitHub"                                                    },
        "owner.github_id"              => { type: "integer", description: "id set on GitHub"                                                     },
        "owner.avatar_url"             => { type: "string", description: "link to avatar (image)"                                                },
        "owner.repositories"           => { "$ref" => "#/defitions/repositories", description: "repositories belonging to this account"          },
        "repository.name"              => { type: "string", description: "the repository's name"                                                 },
        "repository.slug"              => { type: "string", description: "same as {repository.owner.name}/{repository.name}"                     },
        "repository.description"       => { type: "string", description: "the repository's description from GitHub"                              },
        "repository.github_language"   => { type: "string", description: "the main programming language used according to GitHub"                },
        "repository.active"            => { type: "boolean", description: "whether or not this repository is currently enabled on Travis CI"     },
        "repository.private"           => { type: "boolean", description: "whether or not this repository is private"                            },
        "repository.default_branch"    => { "$ref" => "#/defitions/branch", description: "the default branch on GitHub"                          },
        "request.commit"               => { "$ref" => "#/defitions/commit", description: "the commit the request is associated with"             },
        "request.created_at"           => { type: "string",  format: "dateTime", description: "when Travis CI created the request"               },
        "request.config"               => { type: "object", description: "build configuration (as parsed from .travis.yml)"                      },
        "request.branch"               => { type: "object", description: "branch requested to be built"                                          },
        "request.token"                => { type: "object", description: "travis token associated with webhook on GitHub (DEPRECATED)"           },
        "request.result"               => { type: "string"                                                                                       },
        "request.message"              => { type: "string"                                                                                       },
        "request.event_type"           => { type: "string"                                                                                       },
        "user.is_syncing"              => { type: "boolean", description: "whether or not the user is currently being synced with Github"        },
        "user.synced_at"               => { type: "string", format: "dateTime", description: "the last time the user was synced with GitHub"     },
      }

      %w[account broadcast build commit job organization repository request user owner].each do |entry|
        FIELD_DEFITIONS["#{entry}.id"] = {
          type:        "integer",
          description: "value uniquely identifying the #{entry}"
        }
      end

      %w[account job repository request].each do |entry|
        FIELD_DEFITIONS["#{entry}.owner"] = {
          "$ref" => "#/defitions/owner",
          description: "GitHub user or organization the #{entry} belongs to"
        }
      end

      %w[branch build job request].each do |entry|
        FIELD_DEFITIONS["#{entry}.repository"] = {
          "$ref" => "#/defitions/repository",
          description: "GitHub user or organization the #{entry} belongs to"
        }
      end

      DEFINITION_OVERRIDES = {
        owner: {
          properties: MODEL_PROPERTIES.merge({
            "@type" => {
              type: "string",
              pattern: "user|organization",
              description: "either user or organization, depending on what the owner's type is"
            }
          })
        }
      }

      FIELD_DEFITIONS.keys.grep(/^(?:user|organization|owner)\.(.*)$/).flatten.uniq.each do |field|
        field &&= field.split(?., 2).last
        definition = FIELD_DEFITIONS["owner.#{field}"] || FIELD_DEFITIONS["user.#{field}"] || FIELD_DEFITIONS["organization.#{field}"]
        DEFINITION_OVERRIDES[:owner][:properties][field] = definition
      end

      DEFINITIONS = {
        paginationInfo: {
          type: "object",
          properties: {
            limit:    { type: "integer", description: "maximum number of entries included in a single response"       },
            offset:   { type: "integer", description: "how many entries there are overall (not just in the response)" },
            count:    { type: "integer", description: "how many entries there are before the first entry in the list" },
            is_first: { type: "boolean", description: "whether this is the first page of entires"                     },
            is_last:  { type: "boolean", description: "whether this is the last page of entires"                      },
            next:     { "$ref" => "#/definitions/paginationLink", description: "link to the next page"                },
            prev:     { "$ref" => "#/definitions/paginationLink", description: "link to the previous page"            },
            first:    { "$ref" => "#/definitions/paginationLink", description: "link to the first page"               },
            last:     { "$ref" => "#/definitions/paginationLink", description: "link to the last page"                },
          }
        },
        paginationLink: {
          type: "object",
          properties: {
            "@href" => { type: "string",  description: "URL of the page"                                                         },
            offset:    { type: "integer", description: "how many entries there are before the first entry on the page linked to" },
            limit:     { type: "integer", description: "maximum number of entries included in a the page linked to"              },
          }
        },
        pending: {
          type: "object",
          properties: {
            "@type" => { type: "string", pattern: "pending" },
            result_type: { type: "string" }
          }
        },
        error: {
          type: "object",
          properties: {
            "@type"     => { type: "string", pattern: "error"                                            },
            error_type:    { type: "string", description: "error type for machine interpreation"         },
            error_message: { type: "string", description: "error message for human interpretation"       },
            resource_type: { type: "string", description: "type of the resource that caused the error"   },
            permission:    { type: "string", description: "permission that didn't match (if applicable)" },
          }
        }
      }

      RESPONSE_OVERRIDES = {
        error: {
          description: "error response",
          schema: { "$ref" => "#/defitions/error" }
        }
      }

      PARAMETERS = {
        include: {
          name:              "include",
          in:                "query",
          description:       "list fields to eager load",
          required:          false,
          type:              "array",
          items:             { type: "string", description: "field to include ", pattern: "[a-z_]+\.[a-z_]+" },
          collectionFormat:  "csv",
          uniqueItems:       true
        },
        limit: {
          name:              "limit",
          in:                "query",
          description:       "pagniation: how many entries to include in one page",
          required:          false,
          type:              "integer"
        },
        offset: {
          name:              "offset",
          in:                "query",
          description:       "pagniation: how many entries to skip before the first entry on the page",
          required:          false,
          type:              "integer"
        },
        sort_by: {
          name:              "sort_by",
          in:                "query",
          description:       "pagniation: list fields to sort by (without type prefix, optional :desc or :asc suffix per field)",
          required:          false,
          type:              "array",
          items:             { type: "string", description: "field to sort by", pattern: "[a-z_]+(:desc|:asc)?" },
          collectionFormat:  "csv",
          uniqueItems:       true
        },
        request: {
          name:   "request",
          in:     "body",
          schema: { "$ref" => "#/definitions/request" }
        },
        user: {
          name:   "user",
          in:     "body",
          schema: { "$ref" => "#/definitions/user" }
        }
      }

      attr_reader :access_factory, :routes, :prefix, :host

      def initialize(access_factory, routes, prefix, host)
        @access_factory, @routes, @prefix, @host = access_factory, routes, prefix, host
      end

      def to_h
        {
          swagger:     "2.0",
          info:        info,
          host:        host,
          basePath:    prefix,
          schemes:     ["https"],
          consumes:    ["application/json", "application/x-www-form-urlencoded", "multipart/form-data"],
          produces:    ["application/json"],
          paths:       paths,
          definitions: definitions,
          responses:   responses,
          parameters:  PARAMETERS
          #securityDefinitions
          #security
          #tagstags
          #externalDocs
        }
      end

      def paths
        paths = {}

        routes.each do |pattern, actions|
          pattern.to_templates.each do |template|
            entry = paths[template] = {}
            actions.each do |method, service|
              entry[method.downcase] = operation(method, template, service)
            end
          end
        end

        paths
      end

      def operation(method, template, service)
        {
          responses:  responses_for(service),
          parameters: parameters_for(method, template, service),
          deprecated: false
        }
      end

      def parameters_for(method, template, service)
        parameters = []

        template.scan(/\{([^}]+)\}/).each do |(key)|
          parameters << {
            name:         key,
            description:  field_definition(key)[:description],
            in:           "path",
            required:     true,
            type:         field_definition(key)[:type]
          }
        end

        service.params.each do |param|
          next if param.start_with? ?@

          if PARAMETERS.include? param.to_sym
            parameters << { "$ref" => "#/parameters/#{param}"}
          else
            if param.include? ?.
              description = field_definition(param)[:description]
              definition  = param_definition(param)
            else
              real = service.params.detect { |p| p.end_with? ".#{param}" }
              raise "could not find alias for #{param}" unless real
              description = "shorthand for #{real}"
              definition  = param_definition(real)
            end

            parameters << {
              name:         param,
              in:           method == "GET" ? "query" : "formData",
              description:  description,
              required:     false,
            }.merge(definition)
          end
        end

        parameters
      end

      def param_definition(param)
        definition     = field_definition(param)
        data           = { type: definition[:type] }
        data[:pattern] = definition[:pattern] if definition[:pattern]
        data[:format]  = definition[:format]  if definition[:format]

        if LIST_PARAMS.include? param
          data = { type: "array", items: data, collectionFormat: "csv", uniqueItems: true }
        end

        data
      end

      def responses_for(service)
        responses = { "default" => { "$ref" => "#/responses/error" } }
        if [ Services::Job::Cancel ].include? service
          responses["202"] = { "$ref" => "#/responses/pending" }
        else
          responses["200"] = { "$ref" => "#/responses/#{service.result_type}" }
        end
        responses
      end

      def definitions
        renderers.map { |r| definition_for(r) }.compact.to_h.merge(DEFINITIONS)
      end

      def responses
        renderers.map { |r| response_type(r) }.compact.map do |key, description|
          [key, {
            description: description,
            schema: { "$ref" => "#/defitions/#{key}" }
          }.merge(RESPONSE_OVERRIDES[key] || {})]
        end.to_h
      end

      def definition_for(renderer)
        if renderer < Renderer::ModelRenderer
          model_definition_for(renderer)
        elsif renderer < Renderer::CollectionRenderer
          collection_definition_for(renderer.available_attributes.first)
        end
      end

      def singular(entry)
        entry.to_s.sub(/ies$/, "y").sub(/s$/, "")
      end

      def response_type(renderer)
        if renderer < Renderer::ModelRenderer
          [renderer.type, "a single #{renderer.type} object"]
        elsif renderer < Renderer::CollectionRenderer
          [renderer.available_attributes.first, "a list of #{singular renderer.available_attributes.first} objects"]
        elsif renderer == Renderer::Error
          [:error, DEFINITION_OVERRIDES[:error]]
        end
      end

      def collection_definition_for(collection_key)
        return [collection_key, DEFINITION_OVERRIDES[collection_key]] if DEFINITION_OVERRIDES.include? collection_key
        properties = { "@type" => type_definition_for(collection_key) }.merge(MODEL_PROPERTIES)

        properties["@pagination"]  = { "$ref" => "#/definitions/paginationInfo" }
        properties[collection_key] = {
          type:         "array",
          descriptions: "list of #{collection_key}",
          items:        { "$ref" => "#/definitions/#{singular collection_key}" }
        }

        defition = {
          type: "object",
          properties: properties,
          required: ["@type", collection_key]
        }

        [collection_key, defition]
      end

      def model_definition_for(renderer)
        return [renderer.type, DEFINITION_OVERRIDES[renderer.type]] if DEFINITION_OVERRIDES.include? renderer.type
        properties = { "@type" => type_definition_for(renderer.type) }.merge(MODEL_PROPERTIES)
        defition   = { type: "object", properties: properties, required: ["@type"] }
        renderer.available_attributes.each do |attribute|
          properties[attribute] = field_definition(renderer.type.to_s, attribute)
        end
        [renderer.type, defition]
      end

      def field_definition(type, field = nil)
        type, field = type.split(?.) if field.nil?
        specific    = "#{type}.#{field}"
        generic     = "owner.#{field}" if type == "user" or type == "organization"
        generic   ||= specific
        FIELD_DEFITIONS.fetch(specific) { FIELD_DEFITIONS.fetch(generic) }
      end

      def type_definition_for(type)
        { type: "string", pattern: type }
      end

      def info
        {
          title: "Travis CI API",
          version: "3.0",
          contact: {
            name: "Travis CI Support",
            email: "support@travis-ci.com"
          },
          license: {
            name: "MIT",
            url: "https://opensource.org/licenses/MIT"
          }
        }
      end

      def renderers
        Renderer.constants.map { |c| Renderer.const_get(c) }
      end
    end
  end
end
