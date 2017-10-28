class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    def store_return_to
        session[:return_to] = request.referrer
        puts 'STORING: ' + session[:return_to]
    end

    def login
        store_return_to
        flash[:login] = true
    end

    def do_login
        user = params[:login]
        password_hash = params[:hash]


        puts session[:return_to]

        # success
        redirect_to(session[:return_to])
        session[:return_to] = nil
    end
end
