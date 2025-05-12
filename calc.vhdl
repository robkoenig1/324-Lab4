library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc is
port(
    clk:          in std_logic;
    reset:        in std_logic;
    instruction:  in std_logic_vector(7 downto 0);
    pc_out:       out std_logic_vector(3 downto 0);
    printout:     out std_logic_vector(15 downto 0)
);
end calc;

architecture rtl of calc is

    component reg
    generic (
        WIDTH : natural
    );
    port(
        I:     in std_logic_vector(WIDTH-1 downto 0);
        clk:   in std_logic;
        reset: in std_logic;
        en:    in std_logic;
        O:     out std_logic_vector(WIDTH-1 downto 0)
    );
    end component;

    component counter
    port(
        clk:    in std_logic;
        reset:  in std_logic;
        skip:   in std_logic;
        count:  out std_logic_vector(3 downto 0)
    );
    end component;

    component alu
    port(
        A:      in std_logic_vector(15 downto 0);
        B:      in std_logic_vector(15 downto 0);
        op:     in std_logic_vector(1 downto 0);
        result: out std_logic_vector(15 downto 0);
        equal:  out std_logic
    );
    end component;

    signal opcode : std_logic_vector(1 downto 0);
    signal rs : std_logic_vector(1 downto 0);
    signal rt : std_logic_vector(1 downto 0);
    signal rd : std_logic_vector(1 downto 0);
    signal imm : std_logic_vector(3 downto 0);
    signal sign_ext_imm : std_logic_vector(15 downto 0);
    signal reg_wr : std_logic;
    signal reg_dst : std_logic;
    signal alu_op : std_logic_vector(1 downto 0);
    signal alu_src : std_logic;
    signal equ : std_logic;
    signal print_en : std_logic;
    signal ext_en : std_logic;

    --pc signals
    signal pc_reset: std_logic;
    signal pc_skip: std_logic;
    signal pc_value: std_logic_vector(3 downto 0);
    signal skip_next: std_logic;
    signal pc_enable: std_logic;
    signal current_state : std_logic_vector(1 downto 0);
    signal next_state : std_logic_vector(1 downto 0);

    --reg file and signals
    signal reg0_in : std_logic_vector(15 downto 0);
    signal reg1_in : std_logic_vector(15 downto 0);
    signal reg2_in : std_logic_vector(15 downto 0);
    signal reg3_in : std_logic_vector(15 downto 0);
    signal reg0_out : std_logic_vector(15 downto 0);
    signal reg1_out : std_logic_vector(15 downto 0);
    signal reg2_out : std_logic_vector(15 downto 0);
    signal reg3_out : std_logic_vector(15 downto 0);
    signal reg0_en : std_logic;
    signal reg1_en : std_logic;
    signal reg2_en : std_logic;
    signal reg3_en : std_logic;
    signal rf_wr_addr : std_logic_vector(1 downto 0);
    signal rf_wr_data : std_logic_vector(15 downto 0);
    signal rf_wr_en : std_logic;
    signal rf_rd_addr1 : std_logic_vector(1 downto 0);
    signal rf_rd_addr2 : std_logic_vector(1 downto 0);
    signal rf_rd_data1 : std_logic_vector(15 downto 0);
    signal rf_rd_data2 : std_logic_vector(15 downto 0);
    signal printout_reg : std_logic_vector(15 downto 0);

    --alu signals
    signal alu_in_a : std_logic_vector(15 downto 0);
    signal alu_in_b : std_logic_vector(15 downto 0);
    signal alu_result : std_logic_vector(15 downto 0);
    signal alu_equal : std_logic;


begin
    
    --counter instance for pc
    pc_counter: counter
    port map (
        clk => clk,
        reset => pc_reset,
        skip => pc_skip,
        count => pc_value
    );

    pc_out <= pc_value;
    pc_reset <= reset;
    pc_skip <= '0'; --no initial skip

    --current program state control
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= "00";
            skip_next <= '0';
        elsif rising_edge(clk) then
            current_state <= next_state;
            --skip check
            if current_state = "01" and opcode = "11" and alu_equal = '1' then
                skip_next <= '1';
            elsif current_state = "10" then
                skip_next <= '0';
            end if;
        end if;
    end process;
    
    --next program state control 
    process(current_state, skip_next)
    begin
        case current_state is
            when "00" =>
                next_state <= "01";
                
            when "01" =>
                if skip_next = '1' then
                    next_state <= "10";
                    pc_skip <= '1';
                else
                    next_state <= "00";
                    pc_skip <= '0';
                end if;
                
            when "10" =>
                next_state <= "00";
                
            when others =>
                next_state <= "00";
        end case;
    end process;

    --instruction
    opcode <= instruction(7 downto 6);
    rd <= instruction(5 downto 4);
    rt <= instruction(3 downto 2);
    rs <= instruction(1 downto 0);
    imm <= instruction(3 downto 0);
    
    --control signals
    process(opcode)
        --variable temp: integer;
        --variable reg2_en_vec : std_logic_vector(0 downto 0);
    begin
        --reg2_en_vec := (0 => reg2_en);
        --temp := to_integer(unsigned(reg0_out));
        --report " " & integer'image(temp);

        case opcode is
            when "00" => --add
                reg_wr <= '1';
                reg_dst <= '1';
                alu_op <= "11";
                alu_src <= '0';
                equ <= alu_equal;
                print_en <= '0';
            when "01" => --sawp
                reg_wr <= '1';
                reg_dst <= '0';
                alu_op <= "01";
                alu_src <= '0';
                equ <= alu_equal;
                print_en <= '0';
            when "10" => --load
                reg_wr <= '1';
                reg_dst <= '1';
                alu_op <= "10";
                alu_src <= '1';
                equ <= alu_equal;
                print_en <= '0';
            when "11" => --cmp and display
                if rt = "11" then --display (eventually)
                    reg_wr <= '0';
                    reg_dst <= '0';
                    alu_op <= "00";
                    alu_src <= '0';
                    equ <= alu_equal;
                    print_en <= '1';
                else --cmp
                    reg_wr <= '0';
                    reg_dst <= '0';
                    alu_op <= "00";
                    alu_src <= '0';
                    equ <= alu_equal;
                    print_en <= '0';
                end if;
            when others => --else
                null;
        end case;
    end process;

    --sign extention
    sign_ext_imm(3 downto 0) <= imm;
    sign_ext_gen: for i in 4 to 15 generate
        sign_ext_imm(i) <= imm(3);
    end generate;
    
    --register component instantiations
    reg0_inst: reg
    generic map (WIDTH => 16)
    port map (
        I => reg0_in,
        clk => clk,
        reset => reset,
        en => reg0_en,
        O => reg0_out
    );

    reg1_inst: reg
    generic map (WIDTH => 16)
    port map (
        I => reg1_in,
        clk => clk,
        reset => reset,
        en => reg1_en,
        O => reg1_out
    );

    reg2_inst: reg
    generic map (WIDTH => 16)
    port map (
        I => reg2_in,
        clk => clk,
        reset => reset,
        en => reg2_en,
        O => reg2_out
    );

    reg3_inst: reg
    generic map (WIDTH => 16)
    port map (
        I => reg3_in,
        clk => clk,
        reset => reset,
        en => reg3_en,
        O => reg3_out
    );

    --register file read addressing
    rf_rd_addr1 <= rs when (opcode = "00") else rd;
    rf_rd_addr2 <= rt;
    rf_wr_addr <= rd when reg_dst = '1' else rs;

    --register contents fetching
    with rf_rd_addr1 select
        rf_rd_data1 <= reg0_out when "00",
                       reg1_out when "01",
                       reg2_out when "10",
                       reg3_out when others;
              
    with rf_rd_addr2 select
        rf_rd_data2 <= reg0_out when "00",
                       reg1_out when "01",
                       reg2_out when "10",
                       reg3_out when others;

    --register enables
    reg0_en <= '1' when reg_wr = '1' and rf_wr_addr = "00" else '0';
    reg1_en <= '1' when reg_wr = '1' and rf_wr_addr = "01" else '0';
    reg2_en <= '1' when reg_wr = '1' and rf_wr_addr = "10" else '0';
    reg3_en <= '1' when reg_wr = '1' and rf_wr_addr = "11" else '0';

    --alu instantiation
    alu_inst: alu
    port map (
        A => alu_in_a,
        B => alu_in_b,
        op => alu_op,
        result => alu_result,
        equal => alu_equal
    );

    --alu input connections
    alu_in_a <= rf_rd_data1;
    alu_in_b <= sign_ext_imm when alu_src = '1' else rf_rd_data2;

    --register write back
    reg0_in <= alu_result;
    reg1_in <= alu_result;
    reg2_in <= alu_result;
    reg3_in <= alu_result;

    --print output for testbench
    process(clk)
    begin
        if rising_edge(clk) then
            --if print_en = '1' then
            --    printout <= rf_rd_data1;
            if alu_op = "00" then
                printout <= (0 => alu_equal, others => '0');
            else
                printout <= alu_result;
            end if;
        end if;
    end process;
    
end rtl;
