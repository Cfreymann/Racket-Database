import json
from racket import Racket

class RacketDatabase:
    def __init__(self):
        self.rackets = []

    def add_racket(self, racket_object):
        self.rackets.append(racket_object)

    def find_racket(self, racket_name):
        for racket in self.rackets:
            # A more robust search that is case-insensitive
            if racket_name.lower() in racket.name.lower():
                return racket
        return None
    
    def save_to_json(self, filename):
        try:
            with open(filename, 'w') as f:
                # Convert list of Racket objects to list of dictionaries
                json.dump([racket.to_dict() for racket in self.rackets], f, indent=4)
            print(f"\nDatabase successfully saved to {filename}")
        except Exception as e:
            print(f"Error saving database: {e}")

    # Method to load the database from a JSON file on startup
    def load_from_json(self, filename):
        try:
            with open(filename, 'r') as f:
                rackets_data = json.load(f)
                self.rackets = [Racket(**data) for data in rackets_data]
            print(f"Database successfully loaded from {filename}")
        except FileNotFoundError:
            print("No existing database file found. Starting fresh.")
        except Exception as e:
            print(f"Error loading database: {e}")