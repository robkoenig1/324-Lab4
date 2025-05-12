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
    Port ( 
           clk1 : STD_LOGIC;
           clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           sw : in STD_LOGIC_VECTOR (0 to 7);
           seg : out STD_LOGIC_VECTOR (0 to 6);
           cat : out STD_LOGIC);
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
signal seg_temp : STD_LOGIC_VECTOR(3 downto 0) := "0000";
signal cat_temp : STD_LOGIC := '0';
signal instruction_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal pc_value : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
signal printout_value : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal display_value : STD_LOGIC_VECTOR(6 downto 0) := (others => '0'); 
     
signal debounce_counter : unsigned(19 downto 0) := (others => '0');
constant DEBOUNCE_LIMIT : unsigned(19 downto 0) := to_unsigned(500000, 20); -- 10ms at signal
signal is_print_command : STD_LOGIC := '0';
    
begin

calculator: calc
    port map (
        clk => calc_clk,
        reset => reset,
        instruction => instruction_reg,
        pc_out => pc_value,
        printout => printout_value
    );
    
    -- Instantiate the seven-segment display wrapper
    display: KoenigRobert_SSD
    port map (
        seg_in => seg_temp,
        seg => display_value,
        cat_in => cat_temp,
        cat_out => cat
    );
    
    -- Button debouncing process
    process(clk1, reset)
    begin
        if reset = '1' then
            debounce_counter <= (others => '0');
            btn_sync <= "00";
            btn_prev <= '0';
            debounced_button <= '0';
        elsif rising_edge(clk) then
            -- 2-stage synchronizer for button input
            btn_sync <= btn_sync(0) & clk;
            
            -- Start debouncing on button press
            if btn_sync(1) = '1' and btn_prev = '0' then
                debounce_counter <= (others => '0');
            elsif debounce_counter < DEBOUNCE_LIMIT then
                debounce_counter <= debounce_counter + 1;
            end if;
            
            -- Update previous button state
            btn_prev <= btn_sync(1);
            
            -- Button is considered pressed when counter reaches limit
            if debounce_counter = DEBOUNCE_LIMIT and btn_sync(1) = '1' and debounced_button = '0' then
                debounced_button <= '1';
            elsif btn_sync(1) = '0' then
                debounced_button <= '0';
            end if;
        end if;
    end process;
    
    -- Instruction register to hold switch values
    process(clk, reset)
    begin
        if reset = '1' then
            instruction_reg <= (others => '0');
        elsif clk = '1' then
            if debounced_button = '1' and btn_prev = '0' then
                instruction_reg <= sw;
            end if;
        end if;
    end process;
    
    -- Detect print command (opcode 11 and rt = 11)
    is_print_command <= '1' when instruction_reg(7 downto 6) = "11" and instruction_reg(3 downto 2) = "11" else '0';
    
    -- Determine what to display
    process(printout_value, is_print_command)
    begin
        if is_print_command = '1' then
            -- For print command, show the lower 8 bits of the register contents
            display_value <= printout_value(7 downto 0);
        else
            -- For other operations, show operation result if needed
            display_value <= printout_value(7 downto 0);
        end if;
    end process;

end Behavioral;
