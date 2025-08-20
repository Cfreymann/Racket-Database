import requests
from bs4 import BeautifulSoup
import json
import re
from urllib.parse import urljoin, quote_plus

def find_product_url(brand: str, name: str, type_model: str, site_code: str, debug=False) -> str | None:
    """
    Finds a product URL by prioritizing links that contain the word "racquet".
    """
    SITES = {
        'TE': {
            'base_url': "https://www.tennisexpress.com",
            'search_path': "/search?q=",
            # Selector for all product card links
            'link_selector': 'a.product-card-title'
        },
        'TW': {
            'base_url': "https://www.tennis-warehouse.com",
            'search_path': "/search-tennis.html?searchtext=",
            # UPDATED SELECTOR for Tennis Warehouse product grid
            'link_selector': 'div.c-product-grid__product-info > a.c-product-grid__product-link'
        }
    }

    config = SITES.get(site_code)
    if not config:
        print(f"Unknown site code: {site_code}")
        return None

    base_url, search_path, link_selector = config.values()
    full_search_name = f"{brand} {name} {type_model}"
    search_url = f"{base_url}{search_path}{quote_plus(full_search_name)}"
    
    print(f"-> Searching for '{full_search_name}' on {site_code}...")
    
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Connection': 'keep-alive',
        }

        response = requests.get(search_url, headers=headers, timeout=20)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        if debug:
            debug_filename = f"debug_{site_code}.html"
            with open(debug_filename, 'w', encoding='utf-8') as f:
                f.write(soup.prettify())
            print(f"   !!! Saved search results page to '{debug_filename}'")

        all_link_elements = soup.select(link_selector)
        if not all_link_elements:
            print("   ⚠️ No product links found with the current selector.")
            return None

        core_keywords = name.lower().split() + type_model.lower().split()
        
        # --- NEW: Prioritization Logic ---
        racquet_links = []
        other_links = []

        for link in all_link_elements:
            link_text = link.get_text().strip().lower()
            if all(keyword in link_text for keyword in core_keywords) and 'junior' not in link_text and 'demo' not in link_text:
                if 'racquet' in link_text or 'racket' in link_text:
                    racquet_links.append(link) # It's a high-priority match
                else:
                    other_links.append(link) # It's a lower-priority match (like a grommet)
        
        # Prefer links with "racquet" in the title first
        best_match_link = None
        if racquet_links:
            best_match_link = racquet_links[0]
        elif other_links:
            best_match_link = other_links[0]

        if best_match_link and best_match_link.has_attr('href'):
            absolute_url = urljoin(base_url, best_match_link['href'])
            print(f"   ✅ Found best match: {absolute_url}")
            return absolute_url

        print(f"   ⚠️ Could not find a specific match for '{full_search_name}'.")
        return None

    except Exception as e:
        print(f"An error occurred while finding the URL: {e}")
        return None