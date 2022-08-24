control 'Cassandra Node 1 Running' do
  impact 'critical'
  title 'Cassandra Docker instance 1 is running'
  desc 'A Cassandra instance is running and accessible'

  describe docker.images.where { repository == 'bitnami/cassandra' && tag == '4.0.5-debian-11-r1' } do
    it { should exist }
  end
  describe docker.containers.where { names == 'cassandra-node-1' && image == 'bitnami/cassandra:4.0.5-debian-11-r1' } do
    its('status') { should match [/Up/] }
  end
  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-node-1', port: 9042)
  describe cql.query("SELECT cluster_name FROM system.local") do
    its('output') { should match /My Cluster/ }
  end
end

control 'Cassandra Node 2 Running' do
  impact 'critical'
  title 'Cassandra Docker instance 2 is running'
  desc 'A second Cassandra instance is running and accessible'

  describe docker.containers.where { names == 'cassandra-node-2' && image == 'bitnami/cassandra:4.0.5-debian-11-r1' } do
    its('status') { should match [/Up/] }
  end
  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-node-2', port: 9043)
  describe cql.query("SELECT cluster_name FROM system.local") do
    its('output') { should match /My Cluster/ }
  end
end

control 'Cassandra Node 3 Running' do
  impact 'critical'
  title 'Cassandra Docker instance 3 is running'
  desc 'A third Cassandra instance is running and accessible'

  describe docker.containers.where { names == 'cassandra-node-3' && image == 'bitnami/cassandra:4.0.5-debian-11-r1' } do
    its('status') { should match [/Up/] }
  end
  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-node-3', port: 9044)
  describe cql.query("SELECT cluster_name FROM system.local") do
    its('output') { should match /My Cluster/ }
  end
end

control 'Cassandra Benchmark Keyspace' do
  impact 'critical'
  title 'Benchmark Keyspace exists'
  desc 'The benchmark keyspace exists on the Cassandra cluster'

  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-node-1', port: 9042)
  describe cql.query("DESCRIBE KEYSPACE cluster_benchmark") do
    its('output') { should_not match /not found/ }
  end
end

control 'Cassandra Benchmark Table' do
  impact 'critical'
  title 'Words Table  exists'
  desc 'The words table exists in the benchmark keyspace'

  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-node-1', port: 9042)
  describe cql.query("SELECT uuid FROM cluster_benchmark.words") do
    its('output') { should match /d908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e/ }
  end
end

control 'Cassandra Benchmark Keyspace Replication' do
  impact 'critical'
  title 'Benchmark Keyspace Replication 3+'
  desc 'Replication on the Benchmark Keyspace is three or four'

  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-node-1', port: 9042)
  describe cql.query("DESCRIBE KEYSPACE cluster_benchmark") do
    its('output') { should match(/'replication_factor': '3'/).or match(/'replication_factor': '4'/) }
  end
end

control 'Spring Cassandra Keyspace' do
  impact 'critical'
  title 'Spring Keyspace exists'
  desc 'The spring_cassandra keyspace exists on the Cassandra cluster'

  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-node-1', port: 9042)
  describe cql.query("DESCRIBE KEYSPACE spring_cassandra") do
    its('output') { should_not match /not found/ }
  end
end

control 'Spring Cassandra Keyspace Replication' do
  impact 'critical'
  title 'Spring Keyspace Replication 3+'
  desc 'Replication on the Spring Keyspace is three or four'

  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-node-1', port: 9042)
  describe cql.query("DESCRIBE KEYSPACE spring_cassandra") do
    its('output') { should match(/'replication_factor': '3'/).or match(/'replication_factor': '4'/) }
  end
end
