library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity GPS_Interface_Try is
    Port ( Clock        : in        STD_LOGIC;
           GPS_Rx       : in        STD_LOGIC;
           GPS_Tx       : out       STD_LOGIC;
           GPS_3DF      : in        STD_LOGIC;
           GPS_1PPS     : in        STD_LOGIC;
           UART_Tx      : out       STD_LOGIC;
           LED0         : out       STD_LOGIC;
           LED1         : out       STD_LOGIC
           );
end GPS_Interface_Try;

architecture Behavioral of GPS_Interface_Try is

    signal      GPS_Rx_Int                  :   std_logic                           :='0';
    signal      GPS_Tx_Int                  :   std_logic                           :='0';
    signal      GPS_3DF_Int                 :   std_logic                           :='0';
    signal      GPS_1PPS_Int                :   std_logic                           :='0';
    signal      UART_Tx_Int                 :   std_logic                           :='0';
    signal      LED0_Int                    :   std_logic                           :='0';
    signal      LED1_Int                    :   std_logic                           :='0';
    
    signal      Clock_100MHz                :   std_logic                           :='0';
    signal      GPS_Rx_Data                 :   unsigned(7 downto 0)                :=(others=>'0');
    signal      GPS_RX_Valid                :   std_logic                           :='0';
    
    constant    GGA_Identifier		        :	unsigned(15 downto 0)			:= "0100011101000111";
    constant    NEW_LINE                    :   unsigned(7 downto 0)            :=    "00001010";
    constant    CARRIAGE_RETURN             :   unsigned(7 downto 0)            :=    "00001101";
    constant    COMMA                       :   unsigned(7 downto 0)            :=    "00101100";
    constant    DOT                         :   unsigned(7 downto 0)            :=    "00101110";
    constant    MINUS                       :   unsigned(7 downto 0)            :=    "00101101";
    constant    BCD_Digit                   :   unsigned(3 downto 0)            :=    "0011";
    constant    SOUTH                       :   unsigned(7 downto 0)            :=    "01010011";
    constant    WEST                        :   unsigned(7 downto 0)            :=    "01010111";

    signal      Current_Field_Number        :   unsigned(3 downto 0)            :=(others=>'0');
    signal      BCD_Digit_Counter           :   unsigned(3 downto 0)            :=(others=>'0');
    
    signal      Latitude_Minute             :   unsigned(25 downto 0)           :=(others=>'0');
    signal      Latitude_Minute_Signed      :   signed(26 downto 0)             :=(others=>'0');
    signal      Latitude_Degree_Temp        :   unsigned(25 downto 0)           :=(others=>'0');
    signal      Latitude_Minute_Temp        :   unsigned(25 downto 0)           :=(others=>'0');
    signal      Longitude_Minute            :   unsigned(26 downto 0)           :=(others=>'0');
    signal      Longitude_Minute_Signed     :   signed(27 downto 0)             :=(others=>'0');
    signal      Longitude_Degree_Temp       :   unsigned(26 downto 0)           :=(others=>'0');
    signal      Longitude_Minute_Temp       :   unsigned(26 downto 0)           :=(others=>'0');
    signal      Altitude                    :   unsigned(19 downto 0)           :=(others=>'0');
    Signal      Altitude_Signed             :   signed(20 downto 0)             :=(others=>'0');
    signal      The_Last_Two_Letters        :   unsigned(15 downto 0)           :=(others=>'0');
    
    signal      LED_Delay_Counter           :   unsigned(25 downto 0)           :=(others=>'0');
    
    signal      Latitude_Sign               :   std_logic                       :='0';
    signal      Longitude_Sign              :   std_logic                       :='0';
    signal      Altitude_Sign               :   std_logic                       :='0';
    signal      GPS_Valid                   :   std_logic                       :='0';
    
    component clk_wiz_0
    port
     (-- Clock in ports
      -- Clock out ports
      clk_out1          : out    std_logic;
      clk_in1           : in     std_logic
     );
    end component;


begin

    MMCM_12_100MHz : clk_wiz_0
       port map ( 
      -- Clock out ports  
       clk_out1 => Clock_100MHz,
       -- Clock in ports
       clk_in1 => Clock
     );


    RS232_RX : entity work.RS_232_Rx
    port map (Clock    => Clock_100MHz,
              Data_Out => GPS_Rx_Data,
              Valid    => GPS_Rx_Valid,
              Rx       => GPS_Rx_Int
              );

        LED0            <=      LED0_Int;
        LED1            <=      LED1_Int;
        GPS_Tx          <=      '1';
        UART_Tx         <=      UART_Tx_Int;

process(Clock_100MHz)
begin
    if rising_edge(Clock_100MHz) then
            GPS_Rx_Int              <=      GPS_Rx;
            GPS_3DF_Int             <=      GPS_3DF_Int;
            GPS_1PPS_Int            <=      GPS_1PPS;
            UART_Tx_Int             <=      GPS_Rx_Int;
            LED_Delay_Counter       <=  LED_Delay_Counter + 1;
            LED0_Int                <=  LED_Delay_Counter(25);
            LED1_Int                <=  GPS_3DF_Int;
            
            
            if (GPS_Rx_Valid = '1') then
                The_Last_Two_Letters(7 downto 0)    <=      GPS_Rx_Data;
                The_Last_Two_Letters(15 downto 0)   <=      The_Last_Two_Letters(7 downto 0);
                        
                if (The_Last_Two_Letters = GGA_Identifier) then
                    Latitude_Minute                     <=      (others=>'0');
                    Latitude_Minute_Signed              <=      (others=>'0');
                    Latitude_Minute_Temp                <=      (others=>'0');
                    Latitude_Degree_Temp                <=      (others=>'0');
                    Longitude_Minute                    <=      (others=>'0');
                    Longitude_Minute_Signed             <=      (others=>'0');
                    Longitude_Minute_Temp               <=      (others=>'0');
                    Longitude_Degree_Temp               <=      (others=>'0');
                    Altitude                            <=      (others=>'0');
                    Altitude_Signed                     <=      (others=>'0');             
                 end if;
             
                -- extract Latitude
                if (Current_Field_Number = to_unsigned(2, 4)) then
                    BCD_Digit_Counter                   <=  BCD_Digit_Counter + 1;
                    if(BCD_Digit_Counter = to_unsigned(0, 4) or BCD_Digit_Counter = to_unsigned(1, 4)) then
                        Latitude_Degree_Temp            <=  resize(GPS_Rx_Data(3 downto 0), 26)+
                                                            (Latitude_Degree_Temp sll 1)+
                                                            (Latitude_Degree_Temp sll 3);
                    end if;
                    
                    if (BCD_Digit_Counter = to_unsigned(2, 4) or BCD_Digit_Counter=to_unsigned(3, 4)) then
                        Latitude_Minute_Temp            <= resize(GPS_Rx_Data(3 downto 0), 26)+
                                                            (Latitude_Minute_Temp sll 1)+
                                                             (Latitude_Minute_Temp sll 3);
                    end if;
                    
                    if (BCD_Digit_Counter = to_unsigned(4, 4)) then
                        Latitude_Minute            <=       Latitude_Minute_Temp +
                                                            (Latitude_Degree_Temp sll 6) -
                                                            (Latitude_Degree_Temp sll 2);
                    end if;
                    
                    if (BCD_Digit_Counter >= to_unsigned(5, 4) and BCD_Digit_Counter <= to_unsigned(8, 4)) then
                        Latitude_Minute            <=       resize(GPS_Rx_Data(3 downto 0), 26) + 
                                                            (Latitude_Minute sll 3) +
                                                            (Latitude_Minute sll 1);
                    end if;                   
                end if;
                
                if(Current_Field_Number = to_unsigned(3, 4) and BCD_Digit_Counter = to_unsigned(0, 4)) then
                    BCD_Digit_Counter               <=  BCD_Digit_Counter + 1;
                    Latitude_Minute_Signed          <=  signed(resize(Latitude_Minute, 27));
                    if (GPS_Rx_Data = SOUTH) then
                        Latitude_Minute_Signed      <=  to_signed(0, 27) - 
                                                        signed(resize(Latitude_Minute_Signed, 27));
                    end if;
                end if;

              --extract Longitude
              if (Current_Field_Number = to_unsigned(4, 4)) then
                    BCD_Digit_Counter               <=  BCD_Digit_Counter + 1;
                    if (BCD_Digit_Counter>= to_unsigned(0, 4) and BCD_Digit_Counter<=to_unsigned(2, 4)) then
                        Longitude_Degree_Temp       <=  resize(GPS_Rx_Data(3 downto 0), 27)+ 
                                                        (Longitude_Degree_Temp sll 3)+
                                                         (Longitude_Degree_Temp sll 1);   
                    end if;
                    
                    if (BCD_Digit_Counter=to_unsigned(3, 4) or BCD_Digit_Counter=to_unsigned(4, 4)) then
                        Longitude_Minute_Temp       <=  resize(GPS_Rx_Data(3 downto 0), 27) + 
                                                        (Longitude_Minute_Temp sll 1) +
                                                        (Longitude_Minute_Temp sll 3);   
                    end if;
                    
                    if (BCD_Digit_Counter = to_unsigned(5, 4)) then
                        Longitude_Minute            <= Longitude_Minute_Temp +
                                                        (Longitude_Degree_Temp sll 6) -
                                                        (Longitude_Degree_Temp sll 2);
                    end if;
                    
                    if (BCD_Digit_Counter >= to_unsigned(6, 4) and BCD_Digit_Counter <= to_unsigned(9, 4)) then
                        Longitude_Minute            <=  resize(GPS_Rx_Data(3 downto 0), 27) +
                                                        (Longitude_Minute sll 3) +
                                                        (Longitude_Minute sll 1);    
                    end if;
              end if;  
              
              -- finalize longitude
              if (Current_Field_Number=to_unsigned(5, 4)) then
                BCD_Digit_Counter                   <=  BCD_Digit_Counter + 1;
                Longitude_Minute_Signed             <=  signed(resize(Longitude_Minute, 28));
                if (GPS_Rx_Data = WEST) then
                    Longitude_Minute_Signed         <=  to_signed(0, 28) - 
                                                        signed(resize(Longitude_Minute_Signed, 28));
                end if;
              end if;
             end if;
             
             if (Current_Field_Number=to_unsigned(6, 4) and BCD_Digit_Counter=to_unsigned(0, 4)) then
                BCD_Digit_Counter                   <=  BCD_Digit_Counter + 1;
                GPS_Valid                           <=  '0';
                if (GPS_Rx_Data(3 downto 0)=to_unsigned(1, 4)) then
                    GPS_Valid                       <=  '1';    
                end if;
             end if;
             
             if (Current_Field_Number=to_unsigned(9, 4)) then
                if (GPS_Rx_Data = MINUS) then
                    Altitude_Sign                   <=  '1';
                end if;
                
                if (GPS_Rx_Data(7 downto 4)=BCD_Digit) then
                    Altitude                        <=  resize(GPS_Rx_Data(3 downto 0), 20) +
                                                        (Altitude sll 3) +
                                                        (Altitude sll 1);
                end if;
             end if;
             
             if (Current_Field_Number=to_unsigned(10, 4)) then
                Altitude_Signed                     <=  signed(resize(Altitude, 21));
                if (Altitude_Sign = '1') then
                    Altitude_Signed                 <=  to_signed(0, 21) - signed(resize(Altitude, 21));
                end if;
             end if;
             
             if (GPS_Rx_Data = COMMA) then
                 Current_Field_Number                <=      Current_Field_Number + 1;
                 BCD_Digit_Counter                   <=      (others=>'0');    
             end if;
    end if;
end process;
end Behavioral;
