# frozen_string_literal: true

require 'aws-sdk-sts'
require 'aws-sdk-ecr'
require 'k8s-ruby'
require 'logger'

access_key_id = ENV.fetch('AWS_ACCESS_KEY', nil)
secret_access_key = ENV.fetch('AWS_ACCESS_SECRET', nil)
region = ENV['REGION'] || 'eu-west-1'
assume = ENV['ASSUME'] || nil
@logger = Logger.new($stdout)
secret_name = ENV.fetch('IMAGE_PULL_SECRET_NAME', nil)

def generate_token(access_key_id, secret_access_key, region, assume: nil)
  if assume
    puts "Assuming role: #{assume}"

    sts_client = Aws::STS::Client.new(
      region:,
      access_key_id:,
      secret_access_key:
    )

    assumed_role = sts_client.assume_role({
                                            role_arn: assume,
                                            role_session_name: 'ecr-access-session'
                                          })

    credentials = assumed_role.credentials
  else
    credentials = Aws::Credentials.new(
      access_key_id,
      secret_access_key
    )
  end
  ecr_client = if assume
                 Aws::ECR::Client.new(
                   region:,
                   access_key_id: credentials.access_key_id,
                   secret_access_key: credentials.secret_access_key,
                   session_token: credentials.session_token
                 )
               else
                 Aws::ECR::Client.new(
                   region:,
                   access_key_id:,
                   secret_access_key:
                 )
               end
  response = ecr_client.get_authorization_token
  auth_data = response.authorization_data.first

  auth_token = Base64.decode64(auth_data.authorization_token)
  username, password = auth_token.split(':')

  registry_url = auth_data.proxy_endpoint

  docker_config = { 'auths' => {} }

  docker_config['auths'][registry_url] = {
    'auth' => Base64.strict_encode64("#{username}:#{password}").strip
  }
  Base64.strict_encode64(docker_config.to_json)
end

def create_secretes(token, secret_name)
  client = K8s::Client.in_cluster_config
  namespace_api_call = client.api('v1').resource('namespaces').list
  list_of_namespaces = namespace_api_call.map { |namespace| namespace.metadata.name }

  list_of_namespaces.each do |namespace|
    service = K8s::Resource.new({
                                  apiVersion: 'v1',
                                  kind: 'Secret',
                                  metadata: {
                                    namespace:,
                                    name: secret_name
                                  },
                                  labels: {
                                    app: 'registry-creds',
                                    cloud: 'ecr'
                                  },
                                  data: {
                                    '.dockerconfigjson': token
                                  },
                                  type: 'kubernetes.io/dockerconfigjson'
                                })
    begin
      client.api('v1').resource('secrets', namespace:).get(secret_name)
      @logger.info "Secret  #{secret_name} in #{namespace} already exists updating"
      client.api('v1').resource('secrets').update_resource(service)
    rescue K8s::Error::NotFound => e
      @logger.info "Secret #{secret_name} created successfully in #{namespace}."
      client.api('v1').resource('secrets').create_resource(service)
    end
  end
end

token = generate_token(access_key_id, secret_access_key, region, assume:)
while true do 
  create_secretes(token, secret_name)
  sleep(60)
end