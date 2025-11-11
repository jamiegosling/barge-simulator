# Distance Multiplier Analysis

## Current System vs New System

### Distance Matrix Analysis
All route distances in your game:
- Shortest routes: 200 units (London-Exeter, Bristol-Exeter, etc.)
- Average routes: 280-300 units (most routes)
- Longest routes: 500-600 units (Exeter-Boatyard, Exeter-Newcastle, Newcastle-London)

### Average Distance Calculation
Total distance: 6,880 units across 30 routes
Average distance: ~229 units

### New Distance Multiplier System

**Route Categories:**
1. **Very Short Routes (200 units)**: ~0.85x multiplier
   - Example: London-Exeter, Bristol-Exeter
   
2. **Average Routes (280-300 units)**: ~1.0x multiplier  
   - Example: London-Leeds, Leeds-Bristol, most routes
   
3. **Long Routes (400+ units)**: ~1.2-1.5x multiplier
   - Example: Newcastle-London, Exeter-Newcastle

### Reward Comparison Example
Using Coal (base price: £600) with Medium cargo (1.8x multiplier):

**Old System:**
- Short route (200 units): £600 × 11.0 × 1.8 = £11,880
- Average route (280 units): £600 × 15.0 × 1.8 = £16,200  
- Long route (600 units): £600 × 31.0 × 1.8 = £33,480

**New System:**
- Short route (200 units): £600 × 1.8 × 0.85 = £918
- Average route (280 units): £600 × 1.8 × 1.0 = £1,080
- Long route (600 units): £600 × 1.8 × 1.5 = £1,620

### Benefits of New System:
1. **Controlled total rewards**: No more exponential growth with distance
2. **Distance still matters**: Longer routes pay ~50% more than shortest routes
3. **Balanced gameplay**: Short routes are still viable, long routes are more profitable
4. **Predictable economy**: Easier to balance game economy

### Implementation Details:
- Minimum multiplier: 0.7x (prevents extremely low payouts)
- Maximum multiplier: 1.5x (rewards longest routes reasonably)
- Average distance routes: ~1.0x (baseline)
- Minimum reward guarantee: 50% of base × cargo multiplier

The new system makes distance meaningful without breaking the game's economy!
