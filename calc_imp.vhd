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
        printout : out STD_LOGIC_VECTOR (15 downto 0)
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
signal calc_clk : STD_LOGIC := '0';
signal seg_temp : STD_LOGIC_VECTOR(0 to 3) := "0000";
signal cat_temp : STD_LOGIC := '0';
signal instruction_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal pc_value : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
signal printout_value : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal display_value : STD_LOGIC_VECTOR(0 to 6) := (others => '0'); 
signal dig_10 : STD_LOGIC_VECTOR(0 to 3) := (others => '0');
signal dig_1 : STD_LOGIC_VECTOR(0 to 3) := (others => '0');
signal reset_buf : STD_LOGIC;
     
signal debounce_counter : unsigned(19 downto 0) := (others => '0');
constant DEBOUNCE_LIMIT : unsigned(19 downto 0) := to_unsigned(500000, 20); -- 10ms at signal
signal is_print_command : STD_LOGIC := '0';
	
signal clk_temp : unsigned(14 downto 0);
    
begin

reset_buf <= reset;

calculator: calc
    port map (
        clk => sys_clk,
        reset => reset_buf,
        instruction => instruction_reg,
        pc_out => pc_value,
        printout => printout_value
    );
    
    -- Instantiate the seven-segment display binary_read
display: KoenigRobert_SSD
    port map (
        seg_in => seg_temp,
        seg => display_value,
        cat_in => cat_temp,
        cat_out => cat
    );
    
    -- Button debouncing process
    process(clk, reset_buf)
    begin
        if reset_buf = '1' then
            led <= '1';
            btn_sync <= "00";
            btn_prev <= '0';
            debounced_button <= '0';
        elsif rising_edge(clk) then
            btn_sync <= btn_sync(0) & sys_clk;
            
            -- Start debouncing on button press
            --led <= '1';
            if btn_sync(1) = '1' and btn_prev = '0' then
                debounced_button <= '1';
                led <= '0';
            end if;
            
            -- Update previous button state
            btn_prev <= btn_sync(1);
            
        end if;
    end process;
    
    -- Instruction register to hold switch values
    process(sys_clk, reset_buf)
    begin
        if reset_buf = '1' then
            instruction_reg <= (others => '0');
            --led <= '1';
        elsif sys_clk = '1' then
            if debounced_button = '1' and btn_prev = '0' then
                instruction_reg <= sw;
                --led <= '0';
            end if;
        end if;
    end process;
    
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
            --clk_temp <= clk_temp + 1;
            --if clk_temp(clk_count - 1) = '1' then
            --    cat_temp <= not cat_temp;
            --end if;
        end if;
    end process;
    
    -- Detect print command (opcode 11 and rt = 11)
    is_print_command <= '1' when instruction_reg(7 downto 6) = "11" and instruction_reg(3 downto 2) = "11" else '0';
    
    -- Determine what to display
    --process(printout_value, is_print_command)
    process(sys_clk, printout_value, reset_buf)
    variable dec_val : integer range 0 to 255;
    begin
        dec_val := to_integer(unsigned(printout_value(7 downto 0)));
        if reset_buf = '1' then
            dig_10 <= "1010";--std_logic_vector(to_unsigned(dec_val / 10, 4));
            dig_1 <= "1010";--std_logic_vector(to_unsigned(dec_val mod 10, 4));
        elsif is_print_command = '1' then
            dig_10 <= "0011";
            dig_1 <= "0010";
        else
            dig_10 <= "1000";
            dig_1 <= "1000";
        --if rising_edge(clk1) then
        --    display_value <= std_logic_vector(to_unsigned(dec_val mod 10, 4));
        --else 
        --    display_value <= std_logic_vector(to_unsigned(dec_val / 10, 4));
        --end if;
        ----------------------------------------------------------------------------------
        --if is_print_command = '1' then
            -- For print command, show the lower 8 bits of the register contents
        --    display_value <= printout_value(7 downto 0);
        --else
            -- For other operations, show operation result if needed
        --    display_value <= printout_value(7 downto 0);
        end if;
    end process;
    
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
