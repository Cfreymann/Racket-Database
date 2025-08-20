import datetime
class Racket:
    def __init__(self, brand, name, type, weight, head_size, stiffness, string_pattern, url_te=None, url_tw=None, prices=None, last_updated=None):
        self.brand = brand
        self.name = name
        self.type = type
        self.weight = weight
        self.head_size = head_size
        self.stiffness = stiffness
        self.string_pattern = string_pattern
        self.status = "Current"
        self.url_te = url_te
        self.url_tw = url_tw
        self.prices = prices if prices is not None else {}
        self.last_updated = last_updated
    
    def mark_as_old(self):
        self.status = "Outdated"

    def show_details(self):
        print("-" * 30)
        print(f"Brand: {self.brand}")
        print(f"Name: {self.name}")
        print(f"Type: {self.type}")
        print(f"Weight: {self.weight}")
        print(f"Head Size: {self.head_size}")
        print(f"Stiffness: {self.stiffness}")
        print(f"Status: {self.status}")
        print(f"\nTennis Express URL: {self.url_te or 'Not found'}")
        print(f"Tennis Warehouse URL: {self.url_tw or 'Not found'}")
        # Prints information based on racket
        
        if self.prices:
            te_price = self.prices.get('TE', {}).get('sale_price')
            tw_price = self.prices.get('TW', {}).get('sale_price')
            print(f"\nLast Price (TE): ${te_price:.2f}" if te_price else "Last Price (TE): Not available")
            print(f"Last Price (TW): ${tw_price:.2f}" if tw_price else "Last Price (TW): Not available")
            print(f"Last Updated: {self.last_updated}")
        print("-" * 30)

    def to_dict(self):
        return self.__dict__
    # Method to convert object to a dictionary for JSON saving
    