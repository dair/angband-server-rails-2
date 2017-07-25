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

require 'csv'

class ReaderController < ApplicationController
    protect_from_forgery

    def games
        
        @games = AngbandDb.getGameList()

    end

    def events
        id = params[:id]
        @game_id = id
        @game_name = AngbandDb.getGameName(id)
        unless @game_name
            redirect_to '/'
            return
        end
    end

    
    def events_j
        game_id = params[:game_id]
        from = params[:from].to_i
        count = params[:count].to_i

        events = {}
        if game_id != nil and from != nil and count != nil
            events = AngbandDb.getEventList(game_id, from, count)
        end

        render :json => events

    end

    def objects
        id = params[:id]
        @game_id = id
        @game_name = AngbandDb.getGameName(id)
        
        unless @game_name
            redirect_to '/'
            return
        end
    end

    def objects_j
        game_id = params[:game_id]
        
        objects = {}
        if game_id != nil #and from != nil and count != nil
            objects = AngbandDb.getObjectsList(game_id)
        end

        render :json => objects
    end

    def locations
        id = params[:id]
        @game_id = id
        @game_name = AngbandDb.getGameName(id)
        
        unless @game_name
            redirect_to '/'
            return
        end
    end

    def locations_j
        game_id = params[:game_id]
        
        locations = {}
        if game_id != nil #and from != nil and count != nil
            locations = AngbandDb.getLocationsList(game_id)
        end

        render :json => locations
    end
end

