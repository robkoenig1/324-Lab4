library ieee;
use ieee.std_logic_1164.all;

entity counter is
port(
    clk:   in std_logic;  -- rising-edge triggering
    reset: in std_logic;  -- synchronous reset, active high
    skip:  in std_logic;  -- skip count
    count: out std_logic_vector(3 downto 0)  -- 4-bit counter output
);
end counter;

architecture structural of counter is
    -- component declaration for register
    component reg
    generic (
        WIDTH : natural 
    );
    port(    
        I:     in std_logic_vector (WIDTH-1 downto 0);  -- for loading
        clk:   in std_logic;  -- rising-edge triggering 
        reset: in std_logic;
        en:    in std_logic;  -- 0: don't do anything; 1: reg enabled
        O:     out std_logic_vector(WIDTH-1 downto 0)   -- output current register content
    );
    end component;

    signal current_count: std_logic_vector(3 downto 0);   -- current counter value
    signal next_count: std_logic_vector(3 downto 0);      -- next counter value
    signal reg_enable: std_logic;                         -- always enabled for register
    
begin
    reg_enable <= '1'; -- always enables register
    
    -- instantiate register
    counter_reg: reg
    generic map (
        WIDTH => 4
    )
    port map (
        I => next_count,
        clk => clk,
        reset => reset,
        en => reg_enable,
        O => current_count
    );
    
    -- combinational logic to determine next count value
    process(current_count, reset, skip)
    begin

        if (reset = '1') then
            next_count <= "0000"; -- synchronous reset to "0000"
        else
            case current_count is -- increment logic with overflow handling
                when "0000" => next_count <= "0001";
                when "0001" => next_count <= "0010";
                when "0010" => next_count <= "0011";
                when "0011" => next_count <= "0100";
                when "0100" => next_count <= "0101";
                when "0101" => next_count <= "0110";
                when "0110" => next_count <= "0111";
                when "0111" => next_count <= "1000";
                when "1000" => next_count <= "1001";
                when "1001" => next_count <= "1010";
                when "1010" => next_count <= "1011";
                when "1011" => next_count <= "1100";
                when "1100" => next_count <= "1101";
                when "1101" => next_count <= "1110";
                when "1110" => next_count <= "1111";
                when "1111" => next_count <= "0000"; -- overflow to "0000"
                when others => next_count <= "0000"; -- default
            end case;
            if (skip = '1') then
                case current_count is -- increment logic with overflow handling
                    when "0000" => next_count <= "0001";
                    when "0001" => next_count <= "0010";
                    when "0010" => next_count <= "0011";
                    when "0011" => next_count <= "0100";
                    when "0100" => next_count <= "0101";
                    when "0101" => next_count <= "0110";
                    when "0110" => next_count <= "0111";
                    when "0111" => next_count <= "1000";
                    when "1000" => next_count <= "1001";
                    when "1001" => next_count <= "1010";
                    when "1010" => next_count <= "1011";
                    when "1011" => next_count <= "1100";
                    when "1100" => next_count <= "1101";
                    when "1101" => next_count <= "1110";
                    when "1110" => next_count <= "1111";
                    when "1111" => next_count <= "0000"; -- overflow to "0000"
                    when others => next_count <= "0000"; -- default
                end case;
            end if;
        end if;
    end process;
    
    count <= current_count; -- connect current count to output
    
end structural;
