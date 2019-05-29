NAME=ENV.fetch('FUNCTION_NAME', 'aws-ip-range-update')

task :build do
  puts %x{ bundle install --path vendor/bundle }
  puts %x{ mkdir --parent ./build && \
           cat .lambdaignore | xargs  zip -ryv build/lambda.zip . -x  }

end

task :upload do
  puts %x{ aws lambda update-function-code --function-name #{NAME} \
           --zip-file fileb://build/lambda.zip }
end

task :invoke do
  puts %x{ aws lambda invoke --function-name #{NAME} --log-type Tail --query \
          'LogResult' --output text |  base64 -d }
end

task :clean do
  puts %x{ rmdir --ignore-fail-on-non-empty build }
end

task clean_all: :clean do
  puts %x{ rmdir --ignore-fail-on-non-empty .bundle vendor/bundle }
end

task deploy: [:clean_all, :build, :upload] do
  puts NAME
end

task :default => :build
