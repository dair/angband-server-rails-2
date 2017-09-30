#!/usr/bin/env ruby

# скрипт для импорта "старой" базы данных в новую схему

require 'pg'
require 'uri'
require 'optparse'
require 'highline/import'

def get_password(prompt="Enter Password")
    ask(prompt) {|q| q.echo = false}
end


options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
    end

    opts.on("-sFROM", "--source=FROM", "From PostgreSQL db") do |f|
        options[:from] = f
    end

    opts.on("-dTO", "--destination=TO", "To PostgreSQL db") do |t|
        options[:to] = t
    end

    opts.on("-pPREFIX", "--prefix-PREFIX", "Prefix for new tables") do |p|
        options[:prefix] = p
    end

end.parse!


uriFrom = URI.parse(options[:from])

if !options[:prefix] or options[:prefix] == '' then
    puts 'Prefix is not set'
    exit(1)
end

if uriFrom.scheme != 'postgresql' then
    puts 'Scheme must be "postgresql://" and it is "' + uriFrom.scheme + '"'
    exit(1)
end

uriTo = URI.parse(options[:to])
if uriTo.scheme != 'postgresql' then
    puts 'Scheme must be postgresql:// and it is ' + uriTo.scheme
    exit(1)
end


if !uriFrom.password or uriFrom.password == '' then
    uriFrom.password = get_password("Enter password for SOURCE database: ")
end


if !uriTo.password or uriTo.password == '' then
    uriTo.password = get_password("Enter password for DESTINATION database: ")
end

uriFrom.path.slice!(0) if uriFrom.path[0,1] == '/'
uriTo.path.slice!(0) if uriTo.path[0,1] == '/'


begin
    connectionFrom = PG::Connection.open(uriFrom.host, uriFrom.port, nil, nil, uriFrom.path, uriFrom.user, uriFrom.password)
    connectionTo = PG::Connection.open(uriTo.host, uriTo.port, nil, nil, uriTo.path, uriTo.user, uriTo.password)

    puts 'connected!' if options[:verbose]

    # create tables

    # Locations

    toLocationsName = options[:prefix] + "_location"

    # create table
    connectionTo.transaction do |connectionTo|
        query = [
            %{drop table if exists #{toLocationsName} cascade},
            %{create table #{toLocationsName} (id bigint not null, name character varying(255) not null)},
            %{create sequence #{toLocationsName}_SEQ owned by #{toLocationsName}.id},
            %{alter table #{toLocationsName} alter id set default nextval('#{toLocationsName}_SEQ')},
            %{alter table #{toLocationsName} add constraint #{toLocationsName}_PK primary key (id)},
            %{create index index_#{toLocationsName}_name on #{toLocationsName} (name)}]

        for q in query
            puts q if options[:verbose]
            connectionTo.exec(q)
        end

        # fill locations
        rows = connectionFrom.exec(%{select id, name from location})
        q = %{insert into #{toLocationsName} (id, name) values ($1, $2)} 
        connectionTo.prepare('loc_insert', q)
        puts q if options[:verbose]
        rows.each do |r|
            arr = [r["id"], r["name"]]
            connectionTo.exec_prepared('loc_insert', arr)
        end

        # create tags
        toTagName = options[:prefix] + "_tag"
        query = [
            %{drop table if exists #{toTagName} cascade},
            %{create table #{toTagName} (id bigint not null, name varchar(50) not null, status character(1) not null default 'A')},
            %{create sequence #{toTagName}_SEQ owned by #{toTagName}.id},
            %{alter table #{toTagName} add constraint #{toTagName}_PK primary key (id)},
            %{create index INDEX_#{toTagName}_NAME on #{toTagName} (name)}
        ]
        
        for q in query
            puts q if options[:verbose]
            connectionTo.exec(q)
        end

        # fill tags

        rows = connectionFrom.exec(%{select id, name, status from tag})
        q = %{insert into #{toTagName} (id, name, status) values ($1, $2, $3)} 
        connectionTo.prepare('tag_insert', q)
        puts q if options[:verbose]
        rows.each do |r|
            arr = [r["id"], r["name"], r["status"]]
            puts %{\t#{arr}} if options[:verbose]
            connectionTo.exec_prepared('tag_insert', arr)
        end
    end
rescue PG::Error => e
    puts e.message
ensure
    connectionTo.close if connectionTo
    connectionFrom.close if connectionFrom
end

