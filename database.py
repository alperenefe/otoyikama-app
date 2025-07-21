import sqlite3
import datetime
from typing import List, Optional, Tuple

class OtoYikamaDB:
    def __init__(self, db_path: str = "otoyikama.db"):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Veritabanını ve tabloları oluşturur"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS kayitlar (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    plaka TEXT NOT NULL,
                    ad_soyad TEXT NOT NULL,
                    telefon TEXT NOT NULL,
                    hizmet_tipi TEXT NOT NULL,
                    tarih_saat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            conn.commit()
    
    def format_plaka(self, plaka: str) -> str:
        """Plakayı formatlar: 09AEU143 -> 09 AEU 143, 2ABC333 -> 2 ABC 333, 323ABB344 -> 323 ABB 344"""
        plaka = plaka.upper().replace(" ", "")
        
        # Format 1: 09AEU143 (2 rakam + harf + 2-4 rakam)
        if len(plaka) >= 7:
            # İlk 2 karakter rakam mı?
            if plaka[0:2].isdigit():
                # Son 2-4 karakter rakam mı?
                if plaka[-2:].isdigit():
                    # Ortadaki kısım harf mi?
                    middle_part = plaka[2:-2]
                    if middle_part.isalpha():
                        # 09AEU143 formatı
                        if len(plaka) == 7:
                            return f"{plaka[0:2]} {plaka[2:5]} {plaka[5:]}"
                        # 09AEU1434 formatı
                        elif len(plaka) == 8:
                            return f"{plaka[0:2]} {plaka[2:5]} {plaka[5:]}"
                        # 09AEU14345 formatı
                        elif len(plaka) == 9:
                            return f"{plaka[0:2]} {plaka[2:5]} {plaka[5:]}"
        
        # Format 2: 2ABC333 (1 rakam + harf + 3 rakam)
        if len(plaka) >= 6:
            # İlk karakter rakam mı?
            if plaka[0].isdigit():
                # Son 3 karakter rakam mı?
                if plaka[-3:].isdigit():
                    # Ortadaki kısım harf mi?
                    middle_part = plaka[1:-3]
                    if middle_part.isalpha():
                        # 2ABC333 formatı
                        if len(plaka) == 6:
                            return f"{plaka[0]} {plaka[1:4]} {plaka[4:]}"
                        # 2ABC3334 formatı
                        elif len(plaka) == 7:
                            return f"{plaka[0]} {plaka[1:4]} {plaka[4:]}"
        
        # Format 3: 323ABB344 (3 rakam + harf + 3 rakam)
        if len(plaka) >= 9:
            # İlk 3 karakter rakam mı?
            if plaka[0:3].isdigit():
                # Son 3 karakter rakam mı?
                if plaka[-3:].isdigit():
                    # Ortadaki kısım harf mi?
                    middle_part = plaka[3:-3]
                    if middle_part.isalpha():
                        # 323ABB344 formatı
                        if len(plaka) == 9:
                            return f"{plaka[0:3]} {plaka[3:6]} {plaka[6:]}"
                        # 323ABB3444 formatı
                        elif len(plaka) == 10:
                            return f"{plaka[0:3]} {plaka[3:6]} {plaka[6:]}"
        
        return plaka  # Formatlanamazsa olduğu gibi döndür
    
    def kayit_ekle(self, plaka: str, ad_soyad: str, telefon: str, hizmet_tipi: str) -> bool:
        """Yeni araç kaydı ekler"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                formatted_plaka = self.format_plaka(plaka)
                cursor.execute('''
                    INSERT INTO kayitlar (plaka, ad_soyad, telefon, hizmet_tipi)
                    VALUES (?, ?, ?, ?)
                ''', (formatted_plaka, ad_soyad, telefon, hizmet_tipi))
                conn.commit()
                return True
        except sqlite3.Error as e:
            print(f"Veritabanı hatası: {e}")
            return False
    
    def kayit_guncelle(self, kayit_id: int, plaka: str, ad_soyad: str, telefon: str, hizmet_tipi: str) -> bool:
        """Kayıt günceller"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                formatted_plaka = self.format_plaka(plaka)
                cursor.execute('''
                    UPDATE kayitlar 
                    SET plaka = ?, ad_soyad = ?, telefon = ?, hizmet_tipi = ?
                    WHERE id = ?
                ''', (formatted_plaka, ad_soyad, telefon, hizmet_tipi, kayit_id))
                conn.commit()
                return cursor.rowcount > 0
        except sqlite3.Error as e:
            print(f"Veritabanı hatası: {e}")
            return False
    
    def kayit_getir(self, kayit_id: int) -> Optional[Tuple]:
        """Belirli bir kaydı getirir"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('SELECT * FROM kayitlar WHERE id = ?', (kayit_id,))
                return cursor.fetchone()
        except sqlite3.Error as e:
            print(f"Veritabanı hatası: {e}")
            return None
    
    def plaka_ara(self, plaka: str) -> List[Tuple]:
        """Plakaya göre kayıtları arar"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('''
                    SELECT * FROM kayitlar 
                    WHERE plaka LIKE ? 
                    ORDER BY tarih_saat DESC
                ''', (f"%{plaka.upper()}%",))
                return cursor.fetchall()
        except sqlite3.Error as e:
            print(f"Veritabanı hatası: {e}")
            return []
    
    def tum_kayitlar(self) -> List[Tuple]:
        """Tüm kayıtları getirir"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('''
                    SELECT * FROM kayitlar 
                    ORDER BY tarih_saat DESC
                ''')
                return cursor.fetchall()
        except sqlite3.Error as e:
            print(f"Veritabanı hatası: {e}")
            return []
    
    def gunluk_liste(self, tarih: Optional[str] = None) -> List[Tuple]:
        """Günlük kayıtları getirir"""
        try:
            if tarih is None:
                tarih = datetime.date.today().strftime("%Y-%m-%d")
            
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('''
                    SELECT * FROM kayitlar 
                    WHERE DATE(tarih_saat) = ? 
                    ORDER BY tarih_saat DESC
                ''', (tarih,))
                return cursor.fetchall()
        except sqlite3.Error as e:
            print(f"Veritabanı hatası: {e}")
            return []
    
    def kayit_sil(self, kayit_id: int) -> bool:
        """Kaydı siler"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('DELETE FROM kayitlar WHERE id = ?', (kayit_id,))
                conn.commit()
                return cursor.rowcount > 0
        except sqlite3.Error as e:
            print(f"Veritabanı hatası: {e}")
            return False 