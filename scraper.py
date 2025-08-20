import requests
from bs4 import BeautifulSoup
import json
import re
from urllib.parse import urljoin, quote_plus

def find_product_url(racket_name: str, site_base_url: str) -> str | None:
    """
    Searches a website for a racket name and returns the direct product page URL.

    Args:
        racket_name (str): The name of the racket to search for (e.g., "Wilson Pro Staff 97L").
        site_base_url (str): The base URL of the site to search (e.g., "https://www.tennisexpress.com").

    Returns:
        str | None: The absolute URL to the product page, or None if not found.
    """
    try:
        # Step 1: Construct a valid search URL, handling spaces and special characters.
        search_query = quote_plus(racket_name)
        search_url = f"{site_base_url}/search?q={search_query}"
        print(f"-> Searching for URL at: {search_url}")

        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(search_url, headers=headers, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        # Step 2 & 3: Find the first product link in the search results.
        # This selector is specific to Tennis Express and may need updating for other sites.
        link_element = soup.select_one('h3.product-item__title > a')
        
        if link_element and link_element.has_attr('href'):
            # Step 4: Extract the relative path and join it with the base URL.
            relative_url = link_element['href']
            absolute_url = urljoin(site_base_url, relative_url)
            print(f"   ✅ Found product URL: {absolute_url}")
            return absolute_url
        else:
            print("   ⚠️ Could not find a matching product link on the search results page.")
            return None

    except Exception as e:
        print(f"An error occurred while finding the URL: {e}")
        return None


def fetch_prices_from_url(url: str) -> dict:
    """
    Scrapes a product page for sale and original prices using a multi-layered approach.

    Args:
        url (str): The direct URL of the product page to scrape.

    Returns:
        dict: A dictionary containing 'sale_price' and 'original_price'.
    """
    prices = {'sale_price': None, 'original_price': None}
    
    if not url:
        print("   ❌ Cannot fetch prices, URL is missing.")
        return prices
    
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        # --- Method 1: Try JSON-LD (Most Reliable) ---
        all_json_scripts = soup.find_all('script', {'type': 'application/ld+json'})
        product_data = None
        for script in all_json_scripts:
            data = json.loads(script.string)
            if 'hasVariant' in data:
                product_data = data
                break
        
        if product_data:
            variants = product_data.get('hasVariant')
            if variants:
                offer = variants[0].get('offers')
                if offer and offer.get('price'):
                    prices['sale_price'] = float(offer.get('price'))

        # --- Method 2: Check for standard HTML original price (<s> tag) ---
        original_price_element = soup.find('s', {'class': 'money'})
        if original_price_element:
            price_text = original_price_element.get_text()
            prices['original_price'] = float("".join(re.findall(r'[\d.]+', price_text)))

        # --- Method 3: Fallback checks for other HTML structures ---
        if not prices['sale_price']:
            ins_element = soup.select_one('ins > span.amount.discounted')
            if ins_element:
                prices['sale_price'] = float("".join(re.findall(r'[\d.]+', ins_element.get_text())))

        if not prices['original_price']:
            del_element = soup.select_one('del > span.amount')
            if del_element:
                prices['original_price'] = float("".join(re.findall(r'[\d.]+', del_element.get_text())))

        return prices

    except Exception as e:
        print(f"An unexpected error occurred while fetching prices: {e}")
        return prices

# This block allows you to run this file directly for testing
if __name__ == '__main__':
    racket_to_find = "Wilson Pro Staff 97L"
    website_url = "https://www.tennisexpress.com"
    
    print(f"--- Starting test for '{racket_to_find}' on {website_url} ---")
    
    # 1. Automatically find the product URL
    product_page_url = find_product_url(racket_to_find, website_url)
    
    # 2. If a URL was found, scrape it for prices
    if product_page_url:
        print("\n--- Fetching prices from found URL ---")
        scraped_prices = fetch_prices_from_url(product_page_url)
        
        print("-" * 30)

        original = scraped_prices.get('original_price')
        sale = scraped_prices.get('sale_price')

        if not sale and not original:
            print("❌ Could not find any price.")
        elif original and sale and original > sale:
            print(f"Original Price:  ${original:.2f}")
            print(f"Sale Price:      ${sale:.2f} 💰")
            print(f"You Save:        ${original - sale:.2f}")
        elif sale:
            print(f"Current Price:   ${sale:.2f}")
        elif original:
            print(f"Current Price:   ${original:.2f}")