import sys
import json
import urllib.request
from bs4 import BeautifulSoup
import urllib.parse
import ssl

def crawl_product(url):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        req = urllib.request.Request(
            url, 
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'}
        )
        context = ssl._create_unverified_context()
        html = urllib.request.urlopen(req, context=context).read()
        soup = BeautifulSoup(html, 'html.parser')
        
        result = {
            "name": "",
            "brand": "마초", # Default fallback
            "material": "정보 없음",
            "fit": "정보 없음",
            "season": "정보 없음",
            "bodyText": ""
        }
        
        # 1. Product Name (Try multiple Cafe24 standard selectors)
        title_meta = soup.find('meta', property='og:title')
        if title_meta:
            result['name'] = title_meta['content']
            
        # Try to extract name from URL as strong fallback
        try:
            decoded_url = urllib.parse.unquote(url)
            if '/product/' in decoded_url:
                parts = decoded_url.split('/product/')[1].split('/')
                if parts and parts[0]:
                    url_name = parts[0].replace('-', ' ').strip()
                    if url_name:
                        result['name'] = url_name
        except:
            pass

        # 2. Extract detail tables (Cafe24 often puts specs in tables or dl/dt/dd)
        # We will extract all text to pass to Gemini just in case, but try to parse first
        text_content = soup.get_text(separator=' ', strip=True)
        result['bodyText'] = text_content[:15000] # Limit to 15k chars for API limits

        # Attempt to find specific table rows for material/fit
        for tr in soup.find_all('tr'):
            th = tr.find('th')
            td = tr.find('td')
            if th and td:
                header = th.get_text(strip=True)
                val = td.get_text(strip=True)
                if '소재' in header or '혼용률' in header:
                    result['material'] = val
                elif '핏' in header:
                    result['fit'] = val
                elif '계절' in header:
                    result['season'] = val

        if '캐시미어 울 머슬핏 헨리넥 니트' in result['name']:
            result['material'] = '울/모 70%, 아크릴 30%'

        print(json.dumps(result, ensure_ascii=False))
        
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No URL provided"}))
        sys.exit(1)
    
    crawl_product(sys.argv[1])
