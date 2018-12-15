library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.types.all;



entity main is
	port (
		clk: in STD_LOGIC;
		rst_n: in STD_LOGIC;
		tx: out STD_LOGIC;
		rx: in  STD_LOGIC
	);
end main;

architecture Flow of main is


	constant size: integer := 5;

	component bitonicSort is
		generic(
			logN: integer := 3
		);
		port (
			unsorted: in list(2**logN - 1 downto 0);
			sorted:  out list(2**logN - 1 downto 0)
		);
	end component;
	
	
	component UART_RX is
		generic (
			g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
		);
		port (
			i_Clk       : in  std_logic;
			i_RX_Serial : in  std_logic;
			o_RX_DV     : out std_logic;
			o_RX_Byte   : out std_logic_vector(7 downto 0)
		);
	end component;
	
	component UART_TX is
		generic (
			g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
		);
		port (
			i_Clk       : in  std_logic;
			i_TX_DV     : in  std_logic;
			i_TX_Byte   : in  std_logic_vector(7 downto 0);
			o_TX_Active : out std_logic;
			o_TX_Serial : out std_logic;
			o_TX_Done   : out std_logic
		);
	end component;
	
	signal rst: std_logic;
	
	type state_t is (R_s, W_s);
	
	signal state : state_t := R_s;
	
	
	signal input, output: list(2 ** size - 1 downto 0);
	signal count: unsigned(size - 1 downto 0) := (others => '0');
	signal t_data, r_data: unsigned(7 downto 0);
	signal r_ready, t_ready, t_done, t_active : std_logic;
	
begin
	
	rst <= not rst_n;
	
	sort: bitonicSort generic map(logN => size)
							   port map(unsorted => input, sorted => output);
	
	
	receiver: UART_RX generic map (g_CLKS_PER_BIT => 5208)
								port map (i_Clk => clk, i_RX_Serial => rx, o_RX_DV => r_ready, unsigned(o_RX_Byte) => r_data);
	
	
	transmitter: UART_TX generic map (g_CLKS_PER_BIT => 5208)
									port map (i_Clk => clk, i_TX_DV => t_ready, i_TX_Byte => std_logic_vector(t_data), o_TX_Active => t_active, o_TX_Serial => tx, o_TX_Done => t_done);
	
	
	process(rst, r_ready, t_done, count, state)
	begin
		if (rst = '1') then
			state <= R_s;
			count <= (others => '0');
		end if;
		
		case state is
			when R_s => --Read state
				if r_ready'EVENT and r_ready = '1' then
					input(to_integer(count)) <= r_data;
					count <= count + 1;
				end if;
				
				if count = to_unsigned(2 ** size - 1, size) then
					state <= W_s;
					count <= (others => '0');
					t_data <= (others => '0');
					t_ready <= '1';
				end if;
				
			when W_s => --Write state
				if t_done'EVENT and t_done = '1' then
					t_data <= output(to_integer(count));
					count <= count + 1;
					t_ready <= '1';
				end if;
				
				if count = to_unsigned(2 ** size - 1, size) then
					state <= R_s;
					count <= (others => '0');
				end if;
				
		end case;
		
	end process;
	
	

end Flow;

