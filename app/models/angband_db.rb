# coding: UTF-8

# ##################################################################
# Angband Informational Center
# For First Age LARP (http://firstage2013.ru)
# by Vladimir "Dair" Lebedev-Schmidthof <dair@albiongames.org>
# Mk. Albion (http://albiongames.org)
# 
# Copyright (c) 2013 Vladimir Lebedev-Schmidthof
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

end

