# coding: UTF-8

# ##################################################################
# Angband Informational Center
# For First Age LARP (http://firstage2013.ru)
# by Vladimir "Dair" Lebedev-Schmidthof <dair@albiongames.org>
# Mk. Albion (http://albiongames.org)
# 
# Copyright (c) 2013–2017 Vladimir Lebedev-Schmidthof
# ##################################################################
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
# This file is also provided in the root directory of this project
# as LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class AngbandDb < ActiveRecord::Base
    
    def self.getGameList()
        rows = connection.select_all("select id, name from game order by name asc")
        ret = {}
        for i in rows
            id = i["id"]
            name = i["name"]
            ret[id] = name
        end

        return ret
    end

    def self.getGameName(id)
        rows = connection.select_all(sanitize_sql(["select name from game where id = :id", :id => id]))
        unless rows.empty?
            return rows[0]["name"]
        end
        return nil
    end

# id          | bigint                   | NOT NULL DEFAULT nextval('event_seq'::regclass)
# status      | character(1)             | NOT NULL DEFAULT 'N'::bpchar
# title       | character varying(512)   | NOT NULL
# description | text                     | 
# reporter_id | bigint                   | NOT NULL
# location_id | bigint                   | 
# importance  | integer                  | NOT NULL DEFAULT 0
# in_game     | boolean                  | NOT NULL DEFAULT true
# creator     | character varying(255)   | DEFAULT NULL::character varying
# cr_date     | timestamp with time zone | NOT NULL DEFAULT now()
# updater     | character varying(255)   | DEFAULT NULL::character varying
# up_date     | timestamp with time zone | NOT NULL DEFAULT now()

    def self.getEventList(game_id, from, qty)
        query = sanitize_sql(["select e.id, e.title, e.description, e.location_id, l.name as location_name, e.reporter_id, r.name as reporter_name, e.creator, cr.name as cr_name, extract(epoch from e.cr_date) as cr_date, e.updater, up.name as up_name, extract(epoch from e.up_date) as up_date
                                from #{game_id}_event e, #{game_id}_location l, #{game_id}_reporter r, operator cr, operator up
                                where e.status = 'N' and
                                      e.location_id = l.id and
                                      e.reporter_id = r.id and
                                      e.creator = cr.id and
                                      e.updater = up.id
                                order by cr_date desc

                                limit #{qty}
                                offset #{from}"])

        rows = connection.select_all(query)
        ret = {}
        rows.to_hash.each do |row|
            ret[row["id"]] = row
        end

        return ret
    end

end

