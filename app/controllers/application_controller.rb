require 'digest/sha3'

class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    def store_return_to
        session[:return_to] = request.referrer
    end

    def login
        if session[:user]
            redirect_to root_path
        else
            store_return_to
            flash[:login] = true # это чтобы не показывать "вход" в меню входа

            @title = "Вход"
        end
    end

    def do_login
        user = params[:login]
        password_hash = params[:hash]
        success = false

        if user
            stored_hash = AngbandDb.getUserPassword(user)
            hash = Digest::SHA3::hexdigest(session.id + ':' + stored_hash)
            success = (hash == password_hash)
        end

        if success
            session[:user] = {id: user, name: AngbandDb.getUserName(user)}
            # success
            if session[:return_to]
                redirect_to session[:return_to]
                session[:return_to] = nil
            else
                redirect_to root_path
            end
        else
            flash[:fail] = true # для показа сообщения об ошибке
            redirect_to action: 'login'
        end
    end

    def logout
        session[:user] = nil
        redirect_to request.referrer
    end
end
