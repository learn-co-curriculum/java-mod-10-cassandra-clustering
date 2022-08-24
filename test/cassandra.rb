control 'Cassandra Cluster' do
  impact 'critical'
  title 'Cassandra Cluster Up and Ready'
  desc 'A Cassandra Cluster is running with all nodes joined and healthy'

  describe command('nodetool status | grep UN | wc -l') do
    its('stdout') { should match('3').or match('4') }
  end
end
