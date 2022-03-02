RSpec.configure do |c|
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!(95)
  end
end