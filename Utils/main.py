import os
from PIL import Image, ImageDraw

def generate_blob_sprites(outside_color, inside_color, border_color='black', output_folder='autotile_sprites'):
    """
    Generates autotile (blob) sprites based on the layout array.
    Each tile is saved as an individual 32x32 pixel image file.
    """
    
    # Create the output directory if it doesn't exist to avoid cluttering the main folder
    os.makedirs(output_folder, exist_ok=True)
    
    # 1. Define the base Top-Left (TL) quadrants (16x16)
    def make_tl_quad(q_type):
        img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        if q_type == 'I':  # Fully Inside
            draw.rectangle([0, 0, 15, 15], fill=inside_color)
            
        elif q_type == 'V': # Edge Vertical (Outside on Left)
            draw.rectangle([1, 0, 6, 15], fill=outside_color)
            draw.rectangle([8, 0, 15, 15], fill=inside_color)
            draw.line([(7, 0), (7, 15)], fill=border_color)
            draw.line([(0, 0), (0, 15)], fill=border_color)
            
        elif q_type == 'H': # Edge Horizontal (Outside on Top)
            draw.rectangle([0, 1, 15, 6], fill=outside_color)
            draw.rectangle([0, 8, 15, 15], fill=inside_color)
            draw.line([(0, 7), (15, 7)], fill=border_color)
            draw.line([(0, 0), (15, 0)], fill=border_color)
            
        elif q_type == 'C': # Inner Corner (Outside Top-Left)
            draw.rectangle([0, 0, 15, 15], fill=inside_color)
            draw.rectangle([0, 0, 6, 6], fill=outside_color)
            draw.line([(7, 0), (7, 7)], fill=border_color)
            draw.line([(0, 7), (7, 7)], fill=border_color)
            draw.line([(0, 0), (7, 7)], fill=border_color)

        elif q_type == 'O': # Outer Corner (Outside Top-Left)
            draw.rectangle([0, 0, 15, 15], fill=outside_color)
            draw.rectangle([7, 7, 15, 15], fill=inside_color)
            draw.line([(0, 0), (0, 15)], fill=border_color)
            draw.line([(0, 0), (15, 0)], fill=border_color)
            draw.line([(7, 7), (7, 15)], fill=border_color)
            draw.line([(0, 0), (7, 7)], fill=border_color)
            draw.line([(7, 7), (15, 7)], fill=border_color)
            
        return img

    tl_quads = {t: make_tl_quad(t) for t in ['I', 'V', 'H', 'C', 'O']}
    
    tr_quads = {t: img.transpose(Image.FLIP_LEFT_RIGHT) for t, img in tl_quads.items()}
    bl_quads = {t: img.transpose(Image.FLIP_TOP_BOTTOM) for t, img in tl_quads.items()}
    br_quads = {t: tr_quads[t].transpose(Image.FLIP_TOP_BOTTOM) for t in tr_quads}

    def create_tile(tl, tr, bl, br):
        tile = Image.new('RGBA', (32, 32))
        tile.paste(tl_quads[tl], (0, 0))
        tile.paste(tr_quads[tr], (16, 0))
        tile.paste(bl_quads[bl], (0, 16))
        tile.paste(br_quads[br], (16, 16))
        return tile

    layout = [
        ['I,I,I,I', 'C,I,I,I', 'I,C,I,I', 'C,C,I,I', 'I,I,I,C', 'C,I,I,C', 'I,C,I,C', 'C,C,I,C'],
        ['I,I,C,I', 'C,I,C,I', 'I,C,C,I', 'C,C,C,I', 'I,I,C,C', 'C,I,C,C', 'I,C,C,C', 'C,C,C,C'],
        ['V,I,I,I', 'V,C,V,I', 'V,I,V,C', 'V,C,V,C', 'H,H,I,I', 'H,H,I,C', 'H,H,C,I', 'H,H,C,C'], 
        ['I,I,V,V', 'I,V,C,V', 'C,V,I,V', 'C,V,C,V', 'I,I,H,H', 'C,I,H,H', 'I,C,H,H', 'C,C,H,H'],
        ['V,V,V,V', 'H,H,H,H', 'O,H,V,I', 'O,H,V,C', 'H,O,I,V', 'H,O,C,V', 'I,V,H,O', 'C,V,H,O'],
        ['V,I,O,H', 'V,C,O,H', 'O,O,V,V', 'O,H,O,H', 'V,V,O,O', 'H,O,H,O', 'O,O,O,O', None]
    ]

    # Generate and save each valid tile individually
    sprite_count = 0
    for r in range(len(layout)):
        for c in range(len(layout[r])):
            if layout[r][c]:
                quads = layout[r][c].split(',')
                tile_img = create_tile(*quads)
                
                # Format file name (e.g., sprite_00.png, sprite_01.png)
                filename = os.path.join(output_folder, f"sprite_{sprite_count:02d}.png")
                tile_img.save(filename)
                
                sprite_count += 1
                
    print(f"Successfully generated and saved {sprite_count} sprites into the '{output_folder}' directory.")

if __name__ == "__main__":
    # Example using colors similar to Image 2 (Yellows)
    outside_col = "#F8941D"  # Dark yellow border area
    inside_col  = "#F8BF7C"  # Light yellow center area
    
    # Generate and save individual sprites
    generate_blob_sprites(outside_col, inside_col, border_color='black')