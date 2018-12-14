library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity minMax is
		Generic (
			dir: boolean
		);
		Port (
			A: in unsigned(7 downto 0);
			B: in unsigned(7 downto 0);
			nA: out unsigned(7 downto 0);
			nB: out unsigned(7 downto 0)
		);
end minMax;

architecture Behavioral of minMax is
signal comp : unsigned(7 downto 0);
begin
	max:if dir generate
		comp <= (B - A);
	end generate max;
	min:if not dir generate
		comp <= (A - B);
	end generate min;


	nA <=
		A when comp(7) = '1' else
		B;
	nB <= 
		B when comp(7) = '1' else
		A;
	
	
end Behavioral;


