----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/10/2025 04:26:20 PM
-- Design Name: 
-- Module Name: calc_imp - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity calc_imp is
    generic(
        clk_count : integer := 10000
    );
    Port ( 
           clk : in STD_LOGIC;
           sys_clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           sw : in STD_LOGIC_VECTOR (7 downto 0);
           seg : out STD_LOGIC_VECTOR (6 downto 0);
           cat : out STD_LOGIC;
           led : out STD_LOGIC
    );
end calc_imp;

architecture Behavioral of calc_imp is

component calc
    port(
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        instruction : in STD_LOGIC_VECTOR (7 downto 0);
        pc_out : out STD_LOGIC_VECTOR (3 downto 0);
        printout : out STD_LOGIC_VECTOR (15 downto 0);
        skip : out STD_LOGIC
    );
    end component;
    
component KoenigRobert_SSD
    port(
      seg_in : in std_logic_vector(0 to 3);
      cat_in : in std_logic;
      seg : out std_logic_vector(0 to 6);
      cat_out : out std_logic
    );
    end component;
      
signal debounced_button : STD_LOGIC := '0';
signal btn_sync : STD_LOGIC_VECTOR(1 downto 0) := "00";
signal btn_prev : STD_LOGIC := '0';
signal seg_temp : STD_LOGIC_VECTOR(0 to 3) := "0000";
signal cat_temp : STD_LOGIC := '0';
signal instruction_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal pc_value : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
signal printout_value : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal display_value : STD_LOGIC_VECTOR(0 to 6) := (others => '0'); 
signal dig_10 : STD_LOGIC_VECTOR(0 to 3) := (others => '0');
signal dig_1 : STD_LOGIC_VECTOR(0 to 3) := (others => '0');
signal reset_buf : STD_LOGIC;
signal skip_temp : STD_LOGIC;
     
signal is_print_command : STD_LOGIC := '0';
	
signal clk_temp : unsigned(14 downto 0);
    
begin

reset_buf <= reset;

--instantiate calc
calculator: calc
    port map (
        clk => sys_clk,
        reset => reset_buf,
        instruction => instruction_reg,
        pc_out => pc_value,
        printout => printout_value,
        skip => skip_temp
    );
    
--instantiate SSD
display: KoenigRobert_SSD
    port map (
        seg_in => seg_temp,
        seg => display_value,
        cat_in => cat_temp,
        cat_out => cat
    );
    
    --button debouncing process
    process(clk, reset_buf)
    begin
        if reset_buf = '1' then
            led <= '1';
            btn_sync <= "00";
            btn_prev <= '0';
            debounced_button <= '0';
        elsif rising_edge(clk) then
            btn_sync <= btn_sync(0) & sys_clk;
            
            btn_prev <= btn_sync(1);
            
            --start debouncing on button press
            --led <= '1';
            if btn_sync(1) = '1' and btn_prev = '0' then
                debounced_button <= '1';
                led <= '0';
            else 
                debounced_button <= '0';
                --led <= '1';
            end if;
        end if;
    end process;
    
    --instruction register to hold switch values
    --skip_temp <= '1';
    process(sys_clk, reset_buf)
    begin
        if reset_buf = '1' then
            instruction_reg <= "10000000";
            instruction_reg <= "10010000";
            instruction_reg <= "10100000";
            instruction_reg <= "10110000";
            --led <= '1';
        elsif sys_clk = '1' then
            if debounced_button = '1' and skip_temp = '0' then
                instruction_reg <= sw;
                --skip_temp <= '1';
            --else
                --skip_temp <= '0';
            end if;
            --skip_temp <= '0';
        end if;
    end process;
    
    --process to switch SSD digits
    process(clk, reset_buf)
    begin
        if reset_buf = '1' then
            clk_temp <= (others => '0');
            cat_temp <= '0';
        elsif rising_edge(clk) then
            if clk_temp = 9999 then
                clk_temp <= (others => '0');
                cat_temp <= not cat_temp;
            else
                clk_temp <= clk_temp + 1;
            end if;
        end if;
    end process;
    
    --dtect print command
    is_print_command <= '1' when instruction_reg(7 downto 6) = "11" and instruction_reg(3 downto 2) = "11" else '0';

    --determine what to display
    process(sys_clk, reset_buf)
    variable dec_val : integer range -128 to 127;
    variable abs_val : integer range 0 to 127;
    variable negative : STD_LOGIC;
    begin
        dec_val := to_integer(signed(printout_value(7 downto 0)));
        
        if dec_val < 0 then
            negative := '1';
            abs_val := abs(dec_val);
        else
            negative := '0';
            abs_val := dec_val;
        end if;
        
        if reset_buf = '1' then
            dig_10 <= "1010";
            dig_1 <= "1010";
        elsif is_print_command = '1' then
            if negative = '1' then
                if abs_val < 10 then 
                    dig_10 <= "1111";
                    dig_1 <= std_logic_vector(to_unsigned(abs_val mod 10, 4));
                else 
                    dig_10 <= std_logic_vector(to_unsigned(abs_val / 10, 4));
                    dig_1 <= std_logic_vector(to_unsigned(abs_val mod 10, 4));
                end if;
            else 
                dig_10 <= std_logic_vector(to_unsigned(abs_val / 10, 4));
                dig_1 <= std_logic_vector(to_unsigned(abs_val mod 10, 4));
            end if;
        else
            dig_10 <= "1010";
            dig_1 <= "1010";
        end if;
    end process;
    
    --determine which digit to print
    process(cat_temp, dig_1, dig_10)
    begin
        if cat_temp = '0' then 
            --led <= '1';
            seg_temp <= dig_1;
        else 
            seg_temp <= dig_10;
        end if; 
    end process;

seg <= display_value;

end Behavioral;
