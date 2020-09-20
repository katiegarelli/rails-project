class EntriesController < ApplicationController    

    require 'firebase'
    def initialize

        # get our secrets.yml file where our private key is stored
        file_path = File.join(Rails.root, 'config', 'secrets.yml')

        # get the keys in this file for the current env
        config_keys = HashWithIndifferentAccess.new(YAML::load(IO.read(file_path)))[Rails.env]

        # get a firebase client using the secret key
        @firebase = Firebase::Client.new('https://rails-sample-survey.firebaseio.com', config_keys["secret_key_base"])
    end

    def index        
        # get the body which will look like
        # {"-MHTZ5nXxq80_tQksjVM"=>{"answer"=>"test", "password"=>"", "username"=>""}, "-MHTZAStejSCLXyKfRUn"=>{"answer"=>"test", "password"=>"", "username"=>""}, "-MHTZVYVSlZnw20vgF0E"=>{"answer"=>"test", "password"=>"", "username"=>""}, "-MHTcQBPx0aZAs-OTB86"=>{"answer"=>"test", "password"=>"", "username"=>""}}
        body = @firebase.get("entries").body
        logger.debug "entries: #{body}"

        # build a new array
        arr = []


        if body 
            # loop through the body of the response from firebase
            body.each_with_index do |firebaseEntry, index|
                # our firebaseEntry will be something like
                # {"-MHTZ5nXxq80_tQksjVM"=>{"answer"=>"test", "password"=>"", "username"=>""}
                logger.debug "item: #{firebaseEntry}"

                # get the key, aka id from firebase
                key = firebaseEntry[0]
                # and the value aka the rest of the metadata
                val = firebaseEntry[1]

                # add the id to the metadata
                val[:id] = key

                # add our metadata object to the array we created
                arr[index] = val
            end
        end 

        logger.debug "arr: #{arr}"
        # set the array as our response so we can display it
        @entries = arr
    end

    def show
        @entry = @firebase.get("entries/" + params[:id]).body
        @entry[:id] = params[:id]
    end

    def new
    end

    def edit
        id = params[:id]
        body = @firebase.get("entries/" + id).body
        # include the id in the body hash we will create an 
        # entry with so it is passed to the form
        body["id"] = id

        logger.debug "BODY: #{body}"

        @entry = Entry.new(body)
    end

    def create   
        logger.debug "create called!!: #{params[:id]}"     
        @entry = @firebase.push("entries", entry_params)
        redirect_to entries_path
    end

    def update
        logger.debug "update called!!: #{params}"
        @firebase.update('entries/' + params[:id], entry_params)

        redirect_to entries_path
    end
    
    def destroy
        logger.debug "deleting: #{params[:id]}"
        @firebase.delete('entries/' + params[:id])
    
        redirect_to entries_path
    end

    private
    def entry_params
        params.require(:entry).permit(:username, :password, :answer, :id)
    end

end
