import datetime
from racket_database import RacketDatabase
from racket import Racket
import scraper 

# Define a constant for the database filename for easy access
DATABASE_FILE = 'rackets.json'

def main():
    database = RacketDatabase()
    # Load any existing rackets from the file on startup
    database.load_from_json(DATABASE_FILE)

    while True:
        # The main menu for the application
        choice = input("\nWhat would you like to do?:\n"
                       " 1 - Add a new racket\n"
                       " 2 - Find a racket and show details\n"
                       " 3 - Update prices for a racket from the web\n"
                       " 4 - List all rackets\n"
                       " 5 - Exit\n"
                       "Enter your choice: ")

        if choice == '1':
            brand = input("Brand: ")
            name = input("Name (e.g., Pro Staff): ")
            type_model = input("Type/Model (e.g., 97L): ")
            weight = input("Weight (g): ")
            head_size = input("Head Size (sq. in.): ")
            stiffness = input("Stiffness: ")
            string_pattern = input("String Pattern: ")
            
            # Automatically find URLs instead of asking the user
            full_name = f"{brand} {name} {type_model}"
            print(f"\nSearching for '{brand} {name} {type_model}' online...")
            url_te = scraper.find_product_url(brand, name, type_model, 'TE', debug=True)
            url_tw = scraper.find_product_url(brand, name, type_model, 'TW', debug=True)
            
            new_racket = Racket(brand, name, type_model, weight, head_size, stiffness, string_pattern, url_te, url_tw)
            database.add_racket(new_racket)
            print(f"\n'{full_name}' has been added to the database.")

        elif choice == '2':
            search_name = input("Enter the name of the racket to find: ")
            found_racket = database.find_racket(search_name)
            if found_racket:
                found_racket.show_details()
            else:
                print(f"'{search_name}' was not found in the database.")

        elif choice == '3':
            search_name = input("Enter the name of the racket to update prices for: ")
            racket_to_update = database.find_racket(search_name)
            
            if not racket_to_update:
                print(f"'{search_name}' was not found.")
                continue

            print(f"\n--- Fetching prices for {racket_to_update.name} ---")
            
            # Scrape Tennis Express
            if racket_to_update.url_te:
                print("\nChecking Tennis Express...")
                te_prices = scraper.fetch_prices_from_url(racket_to_update.url_te)
                racket_to_update.prices['TE'] = te_prices
            
            # Scrape Tennis Warehouse
            if racket_to_update.url_tw:
                print("\nChecking Tennis Warehouse...")
                tw_prices = scraper.fetch_prices_from_url(racket_to_update.url_tw)
                racket_to_update.prices['TW'] = tw_prices
            
            racket_to_update.last_updated = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print("\n--- Price update complete! ---")
            racket_to_update.show_details()

        elif choice == '4':
            if not database.rackets:
                print("\nThe database is currently empty.")
            else:
                print("\n--- Rackets in Database ---")
                for i, racket in enumerate(database.rackets):
                    print(f"{i + 1}. {racket.brand} {racket.name} {racket.type}")
        
        elif choice == '5':
            # Save the database to the file before exiting
            database.save_to_json(DATABASE_FILE)
            print("\nExiting program. Goodbye! :)")
            break

        else:
            print("\nInvalid c1" \
            "Invalid Choice. Please enter a number from 1 to 5.")

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
