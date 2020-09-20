class EntriesController < ApplicationController    

    require 'firebase'
    def initialize

        # get our secrets.yml file where our private key is stored
        # file_path = File.join(Rails.root, 'config', 'secrets.yml')

        # get the keys in this file for the current env
        # config_keys = HashWithIndifferentAccess.new(YAML::load(IO.read(file_path)))[Rails.env]

        # get a firebase client using the secret key
        @firebase = Firebase::Client.new('https://rails-sample-survey.firebaseio.com', ENV["SECRET_KEY_BASE"])
    end

    def index        
        # get the body which will look like
        # {"-MHTZ5nXxq80_tQksjVM"=>{"answer"=>"test", "username"=>""}, "-MHTZAStejSCLXyKfRUn"=>{"answer"=>"test", "username"=>""}, "-MHTZVYVSlZnw20vgF0E"=>{"answer"=>"test", "username"=>""}, "-MHTcQBPx0aZAs-OTB86"=>{"answer"=>"test", "username"=>""}}
        body = @firebase.get("entries").body
        logger.debug "entries: #{body}"

        # build a new array
        arr = []

        answerCounts = {'Marley' => 0, 'Fred' => 0, 'George' => 0}
        logger.debug "Counts: #{answerCounts}"

        if body 
            # loop through the body of the response from firebase
            body.each_with_index do |firebaseEntry, index|
                # our firebaseEntry will be something like
                # {"-MHTZ5nXxq80_tQksjVM"=>{"answer"=>"test", "username"=>""}
                logger.debug "item: #{firebaseEntry}"

                # get the key, aka id from firebase
                key = firebaseEntry[0]
                # and the value aka the rest of the metadata
                val = firebaseEntry[1]

                # add the id to the metadata
                val[:id] = key

                # add our metadata object to the array we created
                arr[index] = val

                # Get their answer and add it to our answer count object
                case val['answer']
                    when 'Marley' then answerCounts['Marley']+=1
                    when 'Fred' then answerCounts['Fred']+=1
                    when 'George' then answerCounts['George']+=1
                    else logger.debug "Answer didnt match any"
                end

                logger.debug "Counts: #{answerCounts}"
                    
          end
        end 

        # make the counts more readable variables
        marleyCount = answerCounts['Marley']
        fredCount = answerCounts['Fred']
        georgeCount = answerCounts['George']

        # find the winner
        winner="nobody"

        if marleyCount > fredCount && marleyCount > georgeCount 
            winner="Marley"
        elsif georgeCount > fredCount && georgeCount > marleyCount 
            winner="George"
        elsif fredCount > georgeCount && fredCount > marleyCount 
            winner="Fred"
        else 
            logger.debug "There is a Tie"
        end

        logger.debug "arr: #{arr}"
        logger.debug "Winner: #{winner}"

        resp = { 'arr' => arr, 'winner' => winner }
        # set the array as our response so we can display it
        @entries = resp
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
        params.require(:entry).permit(:username, :answer, :id)
    end

end
