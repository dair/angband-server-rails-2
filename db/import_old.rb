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

    connectionTo.transaction do |connectionTo|
        # synchronize operators
        ops = connectionFrom.exec(%{select id, name, password from operator});
        ops.each do |o|
            c = connectionTo.exec(%{select count(*) from operator where id = $1}, [o["id"]])
            if c[0]["count"].to_i == 0
                puts 'Adding new operator `' + o["id"] + '` ("' + o["name"] + '")' if options[:verbose]
                q = %{insert into operator (id, name, password) values ($1, $2, $3)}
                connectionTo.exec(q, [o["id"], o["name"], o["password"]])
            else
                puts 'Skip adding operator `' + o["id"] + '` because one exists already`' if options[:verbose]
                # такой оператор уже есть; ничего не делаем
            end
        end

        # Locations
        toLocationName = options[:prefix] + "_location"
        query = [
            %{drop table if exists #{toLocationName} cascade},
            %{create table #{toLocationName} (id bigint not null, name character varying(255) not null)},
            %{create sequence #{toLocationName}_SEQ owned by #{toLocationName}.id},
            %{alter table #{toLocationName} alter id set default nextval('#{toLocationName}_SEQ')},
            %{alter table #{toLocationName} add constraint #{toLocationName}_PK primary key (id)},
            %{create index index_#{toLocationName}_name on #{toLocationName} (name)}]

        for q in query
            puts q if options[:verbose]
            connectionTo.exec(q)
        end

        # fill locations
        rows = connectionFrom.exec(%{select id, name from location})
        q = %{insert into #{toLocationName} (id, name) values ($1, $2)} 
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

        # reporters
        toReporterName = options[:prefix] + "_reporter"
        query = [
            %{drop table if exists #{toReporterName} cascade},
            %{create table #{toReporterName} (id bigint not null, name character varying(255) not null)},
            %{create sequence #{toReporterName}_SEQ owned by #{toReporterName}.id},
            %{alter table #{toReporterName} alter id set default nextval('#{toReporterName}_SEQ')},
            %{alter table #{toReporterName} add constraint #{toReporterName}_PK primary key (id)},
            %{create index INDEX_#{toReporterName}_NAME on #{toReporterName} (name)}
        ]
        
        for q in query
            puts q if options[:verbose]
            connectionTo.exec(q)
        end

        # fill reporters
        rows = connectionFrom.exec(%{select id, name from reporter})
        q = %{insert into #{toReporterName} (id, name) values ($1, $2)} 
        connectionTo.prepare('reporter_insert', q)
        puts q if options[:verbose]
        rows.each do |r|
            arr = [r["id"], r["name"]]
            puts %{\t#{arr}} if options[:verbose]
            connectionTo.exec_prepared('reporter_insert', arr)
        end

        # events
        toEventName = options[:prefix] + "_event"
        query = [
            %{drop table if exists #{toEventName} cascade},
            %{create table #{toEventName} (id bigint not null, status char(1) not null default 'N', title character varying(512) not null, description text, reporter_id bigint not null, location_id bigint, importance integer not null default 0, in_game boolean not null default true, creator character varying (255) default null, cr_date timestamp with time zone not null default now(), updater character varying (255) default null, up_date timestamp with time zone not null default now())},
            %{create sequence #{toEventName}_SEQ owned by #{toEventName}.id},
            %{alter table #{toEventName} alter id set default nextval('#{toEventName}_SEQ')},
            %{alter table #{toEventName} add constraint #{toEventName}_PK primary key (id)},
            %{alter table #{toEventName} add constraint #{toEventName}_REPORTER_FK foreign key (reporter_id) references #{toReporterName} (id) on delete restrict on update cascade},
            %{alter table #{toEventName} add constraint #{toEventName}_LOCATION_FK foreign key (location_id) references #{toLocationName} (id) on delete restrict on update cascade},
            %{alter table #{toEventName} add constraint #{toEventName}_OPERATOR_CREATOR_FK foreign key (creator) references OPERATOR (id) on delete restrict on update cascade},
            %{alter table #{toEventName} add constraint #{toEventName}_OPERATOR_UPDATER_FK foreign key (updater) references OPERATOR (id) on delete restrict on update cascade},
            %{create index INDEX_#{toEventName}_CR_DATE on #{toEventName} (cr_date)},
            %{create index INDEX_#{toEventName}_UP_DATE on #{toEventName} (up_date)}
        ]
        
        for q in query
            puts q if options[:verbose]
            connectionTo.exec(q)
        end

        # fill events
        q = %{insert into #{toEventName} (id, status, title, description, reporter_id, location_id, importance, in_game, creator, cr_date, updater, up_date) values
            ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)}
        connectionTo.prepare('event_insert', q)

        connectionFrom.transaction do |connectionFrom|
            connectionFrom.exec(%{declare event_cursor cursor for select id, status, title, description, reporter_id, location_id, importance, in_game, creator, cr_date, updater, up_date from event order by id asc})

            while true
                rows = connectionFrom.exec(%{fetch event_cursor})
                break if rows.ntuples == 0
                
                rows.each do |row|
                    row_a = row.values
                    puts row if options[:verbose]
                    connectionTo.exec_prepared('event_insert', row_a)
                end
            end
        end

    end
rescue PG::Error => e
    puts e.message
ensure
    connectionTo.close if connectionTo
    connectionFrom.close if connectionFrom
end

