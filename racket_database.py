import json
from racket import Racket

class RacketDatabase:
    def __init__(self):
        self.rackets = []

    def add_racket(self, racket_object):
        self.rackets.append(racket_object)

    def find_racket(self, search_term):
        """
        Finds a racket by searching against a combined name and type string.
        Prioritizes an exact match before falling back to a partial match.
        """
        search_term_lower = search_term.lower()

        # First pass: Look for an exact match (e.g., "Ezone 98L")
        for racket in self.rackets:
            full_name = f"{racket.name} {racket.type}".lower()
            if search_term_lower == full_name:
                return racket

        # Second pass: If no exact match, look for a partial match
        for racket in self.rackets:
            full_name = f"{racket.name} {racket.type}".lower()
            if search_term_lower in full_name:
                return racket
        
        return None # Return None if no racket is found
    
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