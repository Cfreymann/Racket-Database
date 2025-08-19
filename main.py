import time
from racket_database import RacketDatabase
from racket import Racket

def main():
    database = RacketDatabase()

    racket1 = Racket("Babolat", "Pure Drive", "Team", 285, 100, 68, "16x19")
    racket2 = Racket("Wilson", "Pro Staff", "97L", 290, 97, 65, "16x19")
    # Creates two racket objects yet to be added to the database

    database.add_racket(racket1)
    database.add_racket(racket2)
    # Adds two previously created book objects to the database collection 

    while True:
        choice = int(input("What would you like to do in the library?: "
                        "\n 1 - add a racket"
                        "\n 2 - find a racket"
                        # add option to check status/stats of a racket, maybe
                        # just use "find a racket" bc it does nothing important

                        "\n 3 - exit"
                        "\n"))
        # Menu for database options

        if choice == 1:
            new_brand = input("What brand is the new racket?\n ")
            new_name = input("What is the official name of the new racket?\n ")
            new_type = input("What is the specific type of the new racket?\n ")
            new_weight = input("What is the weight of the new racket?\n ")
            new_head_size = input("What is the head size of the new racket?\n ")
            new_stiffness = input("What is the stiffness of the new racket?\n ")
            new_string_pattern = input("What is the string pattern of the new racket?\n ")
            # need to add preventative statements incase bad information or data type is given

            new_racket = Racket(new_brand, new_name, new_type, new_weight, 
                                new_head_size, new_stiffness, new_string_pattern)

            database.add_racket(new_racket) 
            print(f"The {new_name} {new_type} by {new_brand} has been added to the database sucessfully")
            # The variable "new_racket" is replaced every time a new racket is added but thats not an 
            # issue because the info is stored in a separate Racket() object with a unique name and type

        elif choice == 2:
            search_name = input(f"Please enter the exact racket name you would like to find: ")
            database.find_racket(search_name)
        # Uses racket object created earlier to find name stored within this database
        # stored rackets can be traced back to "rackets" index in racket_database

        elif choice == 3:
            print("exiting database...")
            time.sleep(3)
            print("Goodbye! :)")
            break
        # Exits the database

        else:
            print("Invalid Choice")

if __name__ == "__main__":
    main()

# Additional Functionality:
# - Ensure rackets are permanently added to database, potentially using 
#   a txt document to store the information. Add a save comfirmation 
#
# - Add more specified prompts with higher fault tolerance for incorrect
#   data type entry. Ex - Brand = 100 (integer) should produce an error.
#   Maybe check out variable inputs into the "Racket" object, currently
#   they can be of any data type but you can specify somehow. Also might 
#   consider a more rigid approach giving options like "Which of these 
#   options matches the string pattern", followed by a custom option to 
#   manually add it (should include a warning an an example to prompt the
#   user for exact input)
#
# - Increase racket search specifics by including name as well as type,
#   without this it becomes impossible to search rackets at the type level
#
# - Debating adding price option because of the freequency of updates needed
#   to maintain the proper price, MAYBE an opportunity for testing web scraper
#   functionality. 
#     * Web scraper functionality for searching one tennis website at a 
#       time for one specific racket price is possible. Must integrate into
#       my program and allow for multiple rackets, grip sizes and discounts
#       to be scraped. Also adding a "show prices" option to the menu next to 
#       compare between tennis warehouse vs tennis express
#
# - Further down the line a UI or GUI would make this a proper application,
#   potentially available for use at FST. Maybe use PyQt or pysimplegui
#
# - This system allows even old rackets to be kept in the database for future
#   reference of how it played compared to current rackets. I want to eventually 
#   have so many options for this program that we can really get into the nitty gritty 
#   
# - Figure out how to use git to track changes and updates to the code
#
