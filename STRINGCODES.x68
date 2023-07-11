*-----------------------------------------------------------
* Title      : OPTCODES
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

START:    ORG    $1000

*Used registers:
*A4,A5,A6 = (counter, last opcode, curr opcode)
*$0 in memory is where the string inputs are temporarily stored
*-------------------------------------------*
*------------------MAIN---------------------*
*-------------------------------------------*

               LEA      WELCOME,A1
               MOVE.B   #13,D0
               TRAP     #15 

*---------Read and store --------------
GETADDR1        LEA     ENTADDR1,A1
                MOVE.B  #14,D0
                TRAP    #15
                LEA     $0,A1
                MOVE.B  #2, D0
                TRAP    #15
                MOVE.L  A1,A6
                
                MOVE.L   #0,D4 *wipe saved numbers here
                MOVE.L   #0,D3
                
                CMP.B   #0,D1
                BEQ     INPUTERROR *address is zero chars long
                CMP.B   #8,D1
                BGT     INPUTERROR *address is too large

*ASCII TO HEX CONVERTER TM                            
ASCIILOOP1      ASL.L   #4,D4 *shift by one hex value (not byte)
                NOP
                ADD.B   D3,D4 *add previous hex value to result
                NOP
                MOVE.B  (A1),D3 *get next ascii value
                NOP
                ADD.L   #1,A1 *get next byte
                CMP.B   #0,D1 *check if at end of string
                BEQ     GETADDR2 *if so, conversion is complete
                SUB.B   #1,D1 *subtract size
                
                *check its hexadecimal equvialent
                CMP.B   #$30,D3 *0 in ascii
                BLT     INPUTERROR *invalid character
                CMP.B   #$3A,D3 *: in ascii
                BLT     ASCIINUM1 *byte is 0-9
                CMP.B   #$41,D3 *A in ascii
                BLT     INPUTERROR *invalid character
                CMP.B   #$47,D3 *G in ascii
                BLT     ASCIICHAR1 *byte is A-F
                BRA     INPUTERROR *invalid character

ASCIINUM1       SUB.B   #$30,D3
                BRA     ASCIILOOP1

ASCIICHAR1      SUB.B   #$37,D3
                BRA     ASCIILOOP1

GETADDR2        MOVE.L  D4,A6 *save lower bound; get ready for second
                NOP
                MOVE.L  #0,D4 *wipe saved numbers here
                MOVE.L  #0,D3             
             
*---------Read and store --------------
                LEA     ENTADDR2,A1
                MOVE.B  #14,D0
                TRAP    #15
                LEA     $0,A1
                MOVE.B  #2, D0
                TRAP    #15
                MOVE.L  A1,A5

                CMP.B   #0,D1
                BEQ     INPUTERROR *address is zero chars long    
                CMP.B   #8,D1
                BGT     INPUTERROR *address is too large            

*ASCII TO HEX CONVERTER TM  
ASCIILOOP2      ASL.L   #4,D4 *shift by one hex value (not byte)
                NOP
                ADD.B   D3,D4 *add previous hex value to result
                NOP
                MOVE.B  (A1),D3 *get next ascii value
                NOP
                ADD.L   #1,A1 *get next byte
                CMP.B   #0,D1 *check if at end of string
                BEQ     FINISHADDR2 *if so, conversion is complete
                SUB.B   #1,D1 *subtract size
                
                *check its hexadecimal equvialent
                CMP.B   #$30,D3 *0 in ascii
                BLT     INPUTERROR *invalid character
                CMP.B   #$3A,D3 *: in ascii
                BLT     ASCIINUM2 *byte is 0-9
                CMP.B   #$41,D3 *A in ascii
                BLT     INPUTERROR *invalid character
                CMP.B   #$47,D3 *G in ascii
                BLT     ASCIICHAR2 *byte is A-F
                BRA     INPUTERROR *invalid character                

ASCIINUM2       SUB.B   #$30,D3
                BRA     ASCIILOOP2

ASCIICHAR2      SUB.B   #$37,D3
                BRA     ASCIILOOP2    

FINISHADDR2     MOVE.L  D4,A5

                *error checking
                CMP.L   A6,A5
                BLT     INPUTERROR *Destination < source
                CMP.L   $01000000,A5
                BGT     INPUTERROR *exceeds memory limit
                CMP.L   $01000000,A6
                BGT     INPUTERROR *exceeds memory limit
                
                BSR     FLUSH
                MOVE.L  #0,D4 
                MOVE.W  #31,A4          

*-------------------------------------------*
*--------------OP CODES---------------------*
*-------------------------------------------*

CONTINUE        CMP.W   #0,A4
                BEQ     NEXTPAGE
                CMP.L   A6,A5
                BLT     RESTART
                
                *print current address
                LEA     DOLLAR,A1
                BSR     PRINTSTR
                MOVE.L  #$F0000000,D3 *masking for zeroes
                BSR     PRINTZEROES
                MOVE.L  A6,D1
                MOVE.B  #16,D2
                MOVE.B  #15,D0
                TRAP    #15
                LEA     TB,A1
                BSR     PRINTSTR            
                
                SUB.W   #1,A4
                ADD.L   #4,A6 *adds to address pointer. If you're already handling it just delete it
                
*-------------------------------------------*
*------------INSERT CODE HERE---------------*
*-------------------------------------------*                
                

RESTART         *copied from NEXTPAGE code
                LEA      ENTPAGE,A1
                BSR      PRINTSTR
                MOVE.B   #5,D0 *get a char (in this case, enter key)
                TRAP     #15
                BSR      FLUSH
                
                *ask user to restart
                LEA      STARTAGAIN,A1 
                BSR      PRINTSTR
                MOVE.B   #5,D0 *get a char (y or n)
                TRAP     #15
                BSR      PRINTCRLF
                CMP.B    #$79,D1 *y ascii value
                BEQ      GETADDR1
                
                MOVE.B  #9,D0 *end of line.
                TRAP    #15 

INPUTERROR      BSR     PRINTCRLF
                LEA     ERRMSG,A1
                BSR     PRINTSTR
                JMP     GETADDR1
               
*-------------------------------------------*
*----------------IF DATA--------------------*
*-------------------------------------------*

*---------------- TEMPLATE-------------*

*ea src
IFOPCODEEA      LEA     ERRMSG,A1
                JMP     EASRC 

IFOPCODEEAXD    LEA     ERRMSG,A1
                JMP     EASRCD    

IFOPCODEEAXAI   LEA     ERRMSG,A1
                JMP     EASRCAI

IFOPCODEEAXPR   LEA     ERRMSG,A1
                JMP     EASRCPR 

IFOPCODEEAXPO   LEA     ERRMSG,A1
                JMP     EASRCPO 

*data reg dest
IFOPCODEDXD     LEA     ERRMSG,A1
                JMP     DSRCDDEST                
IFOPCODEAXD     LEA     ERRMSG,A1
                JMP     ASRCDDEST                
IFOPCODEAIXD    LEA     ERRMSG,A1
                JMP     AISRCDDEST                
IFOPCODEIXD     LEA     ERRMSG,A1
                JMP     ISRCDDEST  
IFOPCODEAAXD    LEA     ERRMSG,A1
                JMP     AASRCDDEST                
IFOPCODEPRXD    LEA     ERRMSG,A1
                JMP     PRSRCDDEST                
IFOPCODEPOXD    LEA     ERRMSG,A1
                JMP     POSRCDDEST    

*addr reg dest
IFOPCODEDXA     LEA     ERRMSG,A1
                JMP     DSRCADEST           
IFOPCODEAXA     LEA     ERRMSG,A1
                JMP     ASRCADEST                
IFOPCODEAIXA    LEA     ERRMSG,A1
                JMP     AISRCADEST                
IFOPCODEIXA     LEA     ERRMSG,A1
                JMP     ISRCADEST  
IFOPCODEAAXA    LEA     ERRMSG,A1
                JMP     AASRCADEST                
IFOPCODEPRXA    LEA     ERRMSG,A1
                JMP     PRSRCADEST                
IFOPCODEPOXA    LEA     ERRMSG,A1
                JMP     POSRCADEST  

*addr indr dest
IFOPCODEDXAI    LEA     ERRMSG,A1
                JMP     DSRCADEST                
IFOPCODEAXAI    LEA     ERRMSG,A1
                JMP     ASRCADEST                
IFOPCODEAIXAI   LEA     ERRMSG,A1
                JMP     AISRCADEST                
IFOPCODEIXAI    LEA     ERRMSG,A1
                JMP     ISRCADEST  
IFOPCODEAAXAI   LEA     ERRMSG,A1
                JMP     AASRCADEST               
IFOPCODEPRXAI   LEA     ERRMSG,A1
                JMP     PRSRCADEST                
IFOPCODEPOXAI   LEA     ERRMSG,A1
                JMP     POSRCADEST  

*abs addr dest
IFOPCODEDXAA    LEA     ERRMSG,A1
                JMP     DSRCAADEST                
IFOPCODEAXAA    LEA     ERRMSG,A1
                JMP     ASRCAADEST                
IFOPCODEAIXAA   LEA     ERRMSG,A1
                JMP     AISRCAADEST                
IFOPCODEIXAA    LEA     ERRMSG,A1
                JMP     ISRCAADEST  
IFOPCODEAAXAA   LEA     ERRMSG,A1
                JMP     AASRCAADEST                
IFOPCODEPRXAA   LEA     ERRMSG,A1
                JMP     PRSRCAADEST                
IFOPCODEPOXAA   LEA     ERRMSG,A1
                JMP     POSRCAADEST 

*pre decr dest
IFOPCODEDXPR    LEA     ERRMSG,A1
                JMP     DSRCPRDEST                
IFOPCODEAXPR    LEA     ERRMSG,A1
                JMP     ASRCPRDEST                
IFOPCODEAIXPR   LEA     ERRMSG,A1
                JMP     AISRCPRDEST                
IFOPCODEIXPR    LEA     ERRMSG,A1
                JMP     ISRCPRDEST  
IFOPCODEAAXPR   LEA     ERRMSG,A1
                JMP     AASRCPRDEST               
IFOPCODEPRXPR   LEA     ERRMSG,A1
                JMP     PRSRCPRDEST                
IFOPCODEPOXPR   LEA     ERRMSG,A1
                JMP     POSRCPRDEST    

*post incr dest
IFOPCODEDXPO    LEA     ERRMSG,A1
                JMP     DSRCPODEST                
IFOPCODEAXPO    LEA     ERRMSG,A1
                JMP     ASRCPODEST               
IFOPCODEAIXPO   LEA     ERRMSG,A1
                JMP     AISRCPODEST                
IFOPCODEIXPO    LEA     ERRMSG,A1
                JMP     ISRCPODEST  
IFOPCODEAAXPO   LEA     ERRMSG,A1
                JMP     AASRCPODEST                
IFOPCODEPRXPO   LEA     ERRMSG,A1
                JMP     PRSRCPODEST                
IFOPCODEPOXPO   LEA     ERRMSG,A1
                JMP     POSRCPODEST             

*---------------- MOVE Variants-------------*
  
**MOVE.B
                
*data reg dest
IFMOVEBDXD      LEA     SMOVEB,A1
                JMP     DSRCDDEST                
IFMOVEBAXD      LEA     SMOVEB,A1
                JMP     ASRCDDEST                
IFMOVEBAIXD     LEA     SMOVEB,A1
                JMP     AISRCDDEST                
IFMOVEBIXD      LEA     SMOVEB,A1
                JMP     ISRCDDEST  
IFMOVEBAAXD     LEA     SMOVEB,A1
                JMP     AASRCDDEST                
IFMOVEBPRXD     LEA     SMOVEB,A1
                JMP     PRSRCDDEST                
IFMOVEBPOXD     LEA     SMOVEB,A1
                JMP     POSRCDDEST    

*addr indr dest
IFMOVEBDXAI    LEA     SMOVEB,A1
                JMP     DSRCADEST                
IFMOVEBAXAI    LEA     SMOVEB,A1
                JMP     ASRCADEST                
IFMOVEBAIXAI   LEA     SMOVEB,A1
                JMP     AISRCADEST                
IFMOVEBIXAI    LEA     SMOVEB,A1
                JMP     ISRCADEST  
IFMOVEBAAXAI   LEA     SMOVEB,A1
                JMP     AASRCADEST               
IFMOVEBPRXAI   LEA     SMOVEB,A1
                JMP     PRSRCADEST                
IFMOVEBPOXAI   LEA     SMOVEB,A1
                JMP     POSRCADEST 

*abs addr dest
IFMOVEBDXAA    LEA     SMOVEB,A1
                JMP     DSRCAADEST                
IFMOVEBAXAA    LEA     SMOVEB,A1
                JMP     ASRCAADEST                
IFMOVEBAIXAA   LEA     SMOVEB,A1
                JMP     AISRCAADEST                
IFMOVEBIXAA    LEA     SMOVEB,A1
                JMP     ISRCAADEST  
IFMOVEBAAXAA   LEA     SMOVEB,A1
                JMP     AASRCAADEST                
IFMOVEBPRXAA   LEA     SMOVEB,A1
                JMP     PRSRCAADEST                
IFMOVEBPOXAA   LEA     SMOVEB,A1
                JMP     POSRCAADEST 

*pre decr dest
IFMOVEBDXPR    LEA     SMOVEB,A1
                JMP     DSRCPRDEST                
IFMOVEBAXPR    LEA     SMOVEB,A1
                JMP     ASRCPRDEST                
IFMOVEBAIXPR   LEA     SMOVEB,A1
                JMP     AISRCPRDEST                
IFMOVEBIXPR    LEA     SMOVEB,A1
                JMP     ISRCPRDEST  
IFMOVEBAAXPR   LEA     SMOVEB,A1
                JMP     AASRCPRDEST               
IFMOVEBPRXPR   LEA     SMOVEB,A1
                JMP     PRSRCPRDEST                
IFMOVEBPOXPR   LEA     SMOVEB,A1
                JMP     POSRCPRDEST    

*post incr dest
IFMOVEBDXPO    LEA     SMOVEB,A1
                JMP     DSRCPODEST                
IFMOVEBAXPO    LEA     SMOVEB,A1
                JMP     ASRCPODEST               
IFMOVEBAIXPO   LEA     SMOVEB,A1
                JMP     AISRCPODEST                
IFMOVEBIXPO    LEA     SMOVEB,A1
                JMP     ISRCPODEST  
IFMOVEBAAXPO   LEA     SMOVEB,A1
                JMP     AASRCPODEST                
IFMOVEBPRXPO   LEA     SMOVEB,A1
                JMP     PRSRCPODEST                
IFMOVEBPOXPO   LEA     SMOVEB,A1
                JMP     POSRCPODEST                 
                
**MOVE.W
                
*data reg dest
IFMOVEWDXD      LEA     SMOVEW,A1
                JMP     DSRCDDEST                
IFMOVEWAXD      LEA     SMOVEW,A1
                JMP     ASRCDDEST                
IFMOVEWAIXD     LEA     SMOVEW,A1
                JMP     AISRCDDEST                
IFMOVEWIXD      LEA     SMOVEW,A1
                JMP     ISRCDDEST  
IFMOVEWAAXD     LEA     SMOVEW,A1
                JMP     AASRCDDEST                
IFMOVEWPRXD     LEA     SMOVEW,A1
                JMP     PRSRCDDEST                
IFMOVEWPOXD     LEA     SMOVEW,A1
                JMP     POSRCDDEST    

*addr indr dest
IFMOVEWDXAI    LEA     SMOVEW,A1
                JMP     DSRCADEST                
IFMOVEWAXAI    LEA     SMOVEW,A1
                JMP     ASRCADEST                
IFMOVEWAIXAI   LEA     SMOVEW,A1
                JMP     AISRCADEST                
IFMOVEWIXAI    LEA     SMOVEW,A1
                JMP     ISRCADEST  
IFMOVEWAAXAI   LEA     SMOVEW,A1
                JMP     AASRCADEST               
IFMOVEWPRXAI   LEA     SMOVEW,A1
                JMP     PRSRCADEST                
IFMOVEWPOXAI   LEA     SMOVEW,A1
                JMP     POSRCADEST 

*abs addr dest
IFMOVEWDXAA    LEA     SMOVEW,A1
                JMP     DSRCAADEST                
IFMOVEWAXAA    LEA     SMOVEW,A1
                JMP     ASRCAADEST                
IFMOVEWAIXAA   LEA     SMOVEW,A1
                JMP     AISRCAADEST                
IFMOVEWIXAA    LEA     SMOVEW,A1
                JMP     ISRCAADEST  
IFMOVEWAAXAA   LEA     SMOVEW,A1
                JMP     AASRCAADEST                
IFMOVEWPRXAA   LEA     SMOVEW,A1
                JMP     PRSRCAADEST                
IFMOVEWPOXAA   LEA     SMOVEW,A1
                JMP     POSRCAADEST 

*pre decr dest
IFMOVEWDXPR    LEA     SMOVEW,A1
                JMP     DSRCPRDEST                
IFMOVEWAXPR    LEA     SMOVEW,A1
                JMP     ASRCPRDEST                
IFMOVEWAIXPR   LEA     SMOVEW,A1
                JMP     AISRCPRDEST                
IFMOVEWIXPR    LEA     SMOVEW,A1
                JMP     ISRCPRDEST  
IFMOVEWAAXPR   LEA     SMOVEW,A1
                JMP     AASRCPRDEST               
IFMOVEWPRXPR   LEA     SMOVEW,A1
                JMP     PRSRCPRDEST                
IFMOVEWPOXPR   LEA     SMOVEW,A1
                JMP     POSRCPRDEST    

*post incr dest
IFMOVEWDXPO    LEA     SMOVEW,A1
                JMP     DSRCPODEST                
IFMOVEWAXPO    LEA     SMOVEW,A1
                JMP     ASRCPODEST               
IFMOVEWAIXPO   LEA     SMOVEW,A1
                JMP     AISRCPODEST                
IFMOVEWIXPO    LEA     SMOVEW,A1
                JMP     ISRCPODEST  
IFMOVEWAAXPO   LEA     SMOVEW,A1
                JMP     AASRCPODEST                
IFMOVEWPRXPO   LEA     SMOVEW,A1
                JMP     PRSRCPODEST                
IFMOVEWPOXPO   LEA     SMOVEW,A1
                JMP     POSRCPODEST 

**MOVE.L
                
*data reg dest
IFMOVELDXD      LEA     SMOVEL,A1
                JMP     DSRCDDEST                
IFMOVELAXD      LEA     SMOVEL,A1
                JMP     ASRCDDEST                
IFMOVELAIXD     LEA     SMOVEL,A1
                JMP     AISRCDDEST                
IFMOVELIXD      LEA     SMOVEL,A1
                JMP     ISRCDDEST  
IFMOVELAAXD     LEA     SMOVEL,A1
                JMP     AASRCDDEST                
IFMOVELPRXD     LEA     SMOVEL,A1
                JMP     PRSRCDDEST                
IFMOVELPOXD     LEA     SMOVEL,A1
                JMP     POSRCDDEST    

*addr indr dest
IFMOVELDXAI    LEA     SMOVEL,A1
                JMP     DSRCADEST                
IFMOVELAXAI    LEA     SMOVEL,A1
                JMP     ASRCADEST                
IFMOVELAIXAI   LEA     SMOVEL,A1
                JMP     AISRCADEST                
IFMOVELIXAI    LEA     SMOVEL,A1
                JMP     ISRCADEST  
IFMOVELAAXAI   LEA     SMOVEL,A1
                JMP     AASRCADEST               
IFMOVELPRXAI   LEA     SMOVEL,A1
                JMP     PRSRCADEST                
IFMOVELPOXAI   LEA     SMOVEL,A1
                JMP     POSRCADEST 

*abs addr dest
IFMOVELDXAA    LEA     SMOVEL,A1
                JMP     DSRCAADEST                
IFMOVELAXAA    LEA     SMOVEL,A1
                JMP     ASRCAADEST                
IFMOVELAIXAA   LEA     SMOVEL,A1
                JMP     AISRCAADEST                
IFMOVELIXAA    LEA     SMOVEL,A1
                JMP     ISRCAADEST  
IFMOVELAAXAA   LEA     SMOVEL,A1
                JMP     AASRCAADEST                
IFMOVELPRXAA   LEA     SMOVEL,A1
                JMP     PRSRCAADEST                
IFMOVELPOXAA   LEA     SMOVEL,A1
                JMP     POSRCAADEST 

*pre decr dest
IFMOVELDXPR    LEA     SMOVEL,A1
                JMP     DSRCPRDEST                
IFMOVELAXPR    LEA     SMOVEL,A1
                JMP     ASRCPRDEST                
IFMOVELAIXPR   LEA     SMOVEL,A1
                JMP     AISRCPRDEST                
IFMOVELIXPR    LEA     SMOVEL,A1
                JMP     ISRCPRDEST  
IFMOVELAAXPR   LEA     SMOVEL,A1
                JMP     AASRCPRDEST               
IFMOVELPRXPR   LEA     SMOVEL,A1
                JMP     PRSRCPRDEST                
IFMOVELPOXPR   LEA     SMOVEL,A1
                JMP     POSRCPRDEST    

*post incr dest
IFMOVELDXPO    LEA     SMOVEL,A1
                JMP     DSRCPODEST                
IFMOVELAXPO    LEA     SMOVEL,A1
                JMP     ASRCPODEST               
IFMOVELAIXPO   LEA     SMOVEL,A1
                JMP     AISRCPODEST                
IFMOVELIXPO    LEA     SMOVEL,A1
                JMP     ISRCPODEST  
IFMOVELAAXPO   LEA     SMOVEL,A1
                JMP     AASRCPODEST                
IFMOVELPRXPO   LEA     SMOVEL,A1
                JMP     PRSRCPODEST                
IFMOVELPOXPO   LEA     SMOVEL,A1
                JMP     POSRCPODEST   
               
*---------------- NOP Variants-------------*                
IFNOP           LEA     SNOP,A1
                BSR     PRINTSTR
                JMP     CONTINUE

*---------------- MOVEA Variants-------------*
**MOVEAW
*addr reg dest
IFMOVEAWDXA     LEA     SMOVEAW,A1
                JMP     DSRCADEST           
IFMOVEAWAXA     LEA     SMOVEAW,A1
                JMP     ASRCADEST                
IFMOVEAWAIXA    LEA     SMOVEAW,A1
                JMP     AISRCADEST                
IFMOVEAWIXA     LEA     SMOVEAW,A1
                JMP     ISRCADEST  
IFMOVEAWAAXA    LEA     SMOVEAW,A1
                JMP     AASRCADEST                
IFMOVEAWPRXA    LEA     SMOVEAW,A1
                JMP     PRSRCADEST                
IFMOVEAWPOXA    LEA     SMOVEAW,A1
                JMP     POSRCADEST 

**MOVEAL
*addr reg dest
IFMOVEALDXA     LEA     SMOVEAL,A1
                JMP     DSRCADEST           
IFMOVEALAXA     LEA     SMOVEAL,A1
                JMP     ASRCADEST                
IFMOVEALAIXA    LEA     SMOVEAL,A1
                JMP     AISRCADEST                
IFMOVEALIXA     LEA     SMOVEAL,A1
                JMP     ISRCADEST  
IFMOVEALAAXA    LEA     SMOVEAL,A1
                JMP     AASRCADEST                
IFMOVEALPRXA    LEA     SMOVEAL,A1
                JMP     PRSRCADEST                
IFMOVEALPOXA    LEA     SMOVEAL,A1
                JMP     POSRCADEST 

*--------------MOVEQ VARIANTS----------------*
IFMOVEQIXD      LEA     SMOVEQ,A1
                JMP     ISRCDDEST 

*--------------ADD VARIANTS------------------*
**ADDB
*data reg dest
IFADDBDXD     LEA     SADDB,A1
                JMP     DSRCDDEST                              
IFADDBAIXD    LEA     SADDB,A1
                JMP     AISRCDDEST                
IFADDBIXD     LEA     SADDB,A1
                JMP     ISRCDDEST  
IFADDBAAXD    LEA     SADDB,A1
                JMP     AASRCDDEST                
IFADDBPRXD    LEA     SADDB,A1
                JMP     PRSRCDDEST                
IFADDBPOXD    LEA     SADDB,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFADDBDXAI    LEA     SADDB,A1
                JMP     DSRCADEST                

*abs addr dest
IFADDBDXAA    LEA     SADDB,A1
                JMP     DSRCAADEST                

*pre decr dest
IFADDBDXPR    LEA     SADDB,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFADDBDXPO    LEA     SADDB,A1
                JMP     DSRCPODEST                                          
                
**ADDW
*data reg dest
IFADDWDXD     LEA     SADDW,A1
                JMP     DSRCDDEST                
IFADDWAXD     LEA     SADDW,A1
                JMP     ASRCDDEST                
IFADDWAIXD    LEA     SADDW,A1
                JMP     AISRCDDEST                
IFADDWIXD     LEA     SADDW,A1
                JMP     ISRCDDEST  
IFADDWAAXD    LEA     SADDW,A1
                JMP     AASRCDDEST                
IFADDWPRXD    LEA     SADDW,A1
                JMP     PRSRCDDEST                
IFADDWPOXD    LEA     SADDW,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFADDWDXAI    LEA     SADDW,A1
                JMP     DSRCADEST                

*abs addr dest
IFADDWDXAA    LEA     SADDW,A1
                JMP     DSRCAADEST                

*pre decr dest
IFADDWDXPR    LEA     SADDW,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFADDWDXPO    LEA     SADDW,A1
                JMP     DSRCPODEST   
                
**ADDL          

*data reg dest
IFADDLDXD     LEA     SADDL,A1
                JMP     DSRCDDEST                
IFADDLAXD     LEA     SADDL,A1
                JMP     ASRCDDEST                
IFADDLAIXD    LEA     SADDL,A1
                JMP     AISRCDDEST                
IFADDLIXD     LEA     SADDL,A1
                JMP     ISRCDDEST  
IFADDLAAXD    LEA     SADDL,A1
                JMP     AASRCDDEST                
IFADDLPRXD    LEA     SADDL,A1
                JMP     PRSRCDDEST                
IFADDLPOXD    LEA     SADDL,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFADDLDXAI    LEA     SADDL,A1
                JMP     DSRCADEST                

*abs addr dest
IFADDLDXAA    LEA     SADDL,A1
                JMP     DSRCAADEST                

*pre decr dest
IFADDLDXPR    LEA     SADDL,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFADDLDXPO    LEA     SADDL,A1
                JMP     DSRCPODEST         

*--------------ADDA VARIANTS-----------------*
**ADDAW
*addr reg dest
IFADDAWDXA     LEA     SADDAW,A1
                JMP     DSRCADEST           
IFADDAWAXA     LEA     SADDAW,A1
                JMP     ASRCADEST                
IFADDAWAIXA    LEA     SADDAW,A1
                JMP     AISRCADEST                
IFADDAWIXA     LEA     SADDAW,A1
                JMP     ISRCADEST  
IFADDAWAAXA    LEA     SADDAW,A1
                JMP     AASRCADEST                
IFADDAWPRXA    LEA     SADDAW,A1
                JMP     PRSRCADEST                
IFADDAWPOXA    LEA     SADDAW,A1
                JMP     POSRCADEST 

**ADDAL

*addr reg dest
IFADDALDXA     LEA     SADDAL,A1
                JMP     DSRCADEST           
IFADDALAXA     LEA     SADDAL,A1
                JMP     ASRCADEST                
IFADDALAIXA    LEA     SADDAL,A1
                JMP     AISRCADEST                
IFADDALIXA     LEA     SADDAL,A1
                JMP     ISRCADEST  
IFADDALAAXA    LEA     SADDAL,A1
                JMP     AASRCADEST                
IFADDALPRXA    LEA     SADDAL,A1
                JMP     PRSRCADEST                
IFADDALPOXA    LEA     SADDAL,A1
                JMP     POSRCADEST 

*--------------ADDQ VARIANTS-----------------*
**ADDQB
*data reg dest             
IFADDQBIXD     LEA     SADDQB,A1
                JMP     ISRCDDEST   

*addr reg dest               
IFADDQBIXA     LEA     SADDQB,A1
                JMP     ISRCADEST  

*addr indr dest             
IFADDQBIXAI    LEA     SADDQB,A1
                JMP     ISRCADEST  

*abs addr dest             
IFADDQBIXAA    LEA     SADDQB,A1
                JMP     ISRCAADEST  

*pre decr dest                
IFADDQBIXPR    LEA     SADDQB,A1
                JMP     ISRCPRDEST   

*post incr dest            
IFADDQBIXPO    LEA     SADDQB,A1
                JMP     ISRCPODEST  

**ADDQW
*data reg dest 
IFADDQWIXD     LEA     SADDQW,A1
                JMP     ISRCDDEST   

*addr reg dest               
IFADDQWIXA     LEA     SADDQW,A1
                JMP     ISRCADEST  

*addr indr dest             
IFADDQWIXAI    LEA     SADDQW,A1
                JMP     ISRCADEST  

*abs addr dest             
IFADDQWIXAA    LEA     SADDQW,A1
                JMP     ISRCAADEST  

*pre decr dest                
IFADDQWIXPR    LEA     SADDQW,A1
                JMP     ISRCPRDEST   

*post incr dest            
IFADDQWIXPO    LEA     SADDQW,A1
                JMP     ISRCPODEST 

**ADDQL
*data reg dest 
IFADDQLIXD     LEA     SADDQL,A1
                JMP     ISRCDDEST   

*addr reg dest               
IFADDQLIXA     LEA     SADDQL,A1
                JMP     ISRCADEST  
                
*addr indr dest             
IFADDQLIXAI    LEA     SADDQL,A1
                JMP     ISRCADEST  

*abs addr dest             
IFADDQLIXAA    LEA     SADDQL,A1
                JMP     ISRCAADEST  

*pre decr dest                
IFADDQLIXPR    LEA     SADDQL,A1
                JMP     ISRCPRDEST   

*post incr dest            
IFADDQLIXPO    LEA     SADDQL,A1
                JMP     ISRCPODEST  

*--------------------SUB VARIANTS------------*
**SUBB
*data reg dest
IFSUBBDXD     LEA     SSUBB,A1
                JMP     DSRCDDEST                              
IFSUBBAIXD    LEA     SSUBB,A1
                JMP     AISRCDDEST                
IFSUBBIXD     LEA     SSUBB,A1
                JMP     ISRCDDEST  
IFSUBBAAXD    LEA     SSUBB,A1
                JMP     AASRCDDEST                
IFSUBBPRXD    LEA     SSUBB,A1
                JMP     PRSRCDDEST                
IFSUBBPOXD    LEA     SSUBB,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFSUBBDXAI    LEA     SSUBB,A1
                JMP     DSRCADEST                

*abs addr dest
IFSUBBDXAA    LEA     SSUBB,A1
                JMP     DSRCAADEST                

*pre decr dest
IFSUBBDXPR    LEA     SSUBB,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFSUBBDXPO    LEA     SSUBB,A1
                JMP     DSRCPODEST                                          
                
**SUBW
*data reg dest
IFSUBWDXD     LEA     SSUBW,A1
                JMP     DSRCDDEST                
IFSUBWAXD     LEA     SSUBW,A1
                JMP     ASRCDDEST                
IFSUBWAIXD    LEA     SSUBW,A1
                JMP     AISRCDDEST                
IFSUBWIXD     LEA     SSUBW,A1
                JMP     ISRCDDEST  
IFSUBWAAXD    LEA     SSUBW,A1
                JMP     AASRCDDEST                
IFSUBWPRXD    LEA     SSUBW,A1
                JMP     PRSRCDDEST                
IFSUBWPOXD    LEA     SSUBW,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFSUBWDXAI    LEA     SSUBW,A1
                JMP     DSRCADEST                

*abs addr dest
IFSUBWDXAA    LEA     SSUBW,A1
                JMP     DSRCAADEST                

*pre decr dest
IFSUBWDXPR    LEA     SSUBW,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFSUBWDXPO    LEA     SSUBW,A1
                JMP     DSRCPODEST   
                
**SUBL          

*data reg dest
IFSUBLDXD     LEA     SSUBL,A1
                JMP     DSRCDDEST                
IFSUBLAXD     LEA     SSUBL,A1
                JMP     ASRCDDEST                
IFSUBLAIXD    LEA     SSUBL,A1
                JMP     AISRCDDEST                
IFSUBLIXD     LEA     SSUBL,A1
                JMP     ISRCDDEST  
IFSUBLAAXD    LEA     SSUBL,A1
                JMP     AASRCDDEST                
IFSUBLPRXD    LEA     SSUBL,A1
                JMP     PRSRCDDEST                
IFSUBLPOXD    LEA     SSUBL,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFSUBLDXAI    LEA     SSUBL,A1
                JMP     DSRCADEST                

*abs addr dest
IFSUBLDXAA    LEA     SSUBL,A1
                JMP     DSRCAADEST                

*pre decr dest
IFSUBLDXPR    LEA     SSUBL,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFSUBLDXPO    LEA     SSUBL,A1
                JMP     DSRCPODEST 

*---------------- LEA Variants-------------*
*addr indr dest                          
IFLEAAIXAI      LEA     SLEA,A1
                JMP     AISRCADEST                 
IFLEAAAXAI      LEA     SLEA,A1
                JMP     AASRCADEST               

*---------------- NOT Variants-------------*
**NOT.B
*effective addresses
IFNOTBEA         LEA     SNOTB,A1
                JMP     EASRC 

IFNOTBEAXD       LEA     SNOTB,A1
                JMP     EASRCD    

IFNOTBEAXAI      LEA     SNOTB,A1
                JMP     EASRCAI

IFNOTBEAXPR      LEA     SNOTB,A1
                JMP     EASRCPR 

IFNOTBEAXPO      LEA     SNOTB,A1
                JMP     EASRCPO 
                
**NOT.W
*effective addresses
IFNOTWEA         LEA     SNOTW,A1
                JMP     EASRC 

IFNOTWEAXD       LEA     SNOTW,A1
                JMP     EASRCD    

IFNOTWEAXAI      LEA     SNOTW,A1
                JMP     EASRCAI

IFNOTWEAXPR      LEA     SNOTW,A1
                JMP     EASRCPR 

IFNOTWEAXPO      LEA     SNOTW,A1
                JMP     EASRCPO 

**NOT.L
*effective addresses
IFNOTLEA         LEA     SNOTL,A1
                JMP     EASRC 

IFNOTLEAXD       LEA     SNOTL,A1
                JMP     EASRCD    

IFNOTLEAXAI      LEA     SNOTL,A1
                JMP     EASRCAI

IFNOTLEAXPR      LEA     SNOTL,A1
                JMP     EASRCPR 

IFNOTLEAXPO      LEA     SNOTL,A1
                JMP     EASRCPO                 

*---------------- AND Variants-------------*
**ANDB
*data reg dest
IFANDBDXD     LEA     SANDB,A1
                JMP     DSRCDDEST                              
IFANDBAIXD    LEA     SANDB,A1
                JMP     AISRCDDEST                
IFANDBIXD     LEA     SANDB,A1
                JMP     ISRCDDEST  
IFANDBAAXD    LEA     SANDB,A1
                JMP     AASRCDDEST                
IFANDBPRXD    LEA     SANDB,A1
                JMP     PRSRCDDEST                
IFANDBPOXD    LEA     SANDB,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFANDBDXAI    LEA     SANDB,A1
                JMP     DSRCADEST                

*abs addr dest
IFANDBDXAA    LEA     SANDB,A1
                JMP     DSRCAADEST                

*pre decr dest
IFANDBDXPR    LEA     SANDB,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFANDBDXPO    LEA     SANDB,A1
                JMP     DSRCPODEST                                          
                
**ANDW
*data reg dest
IFANDWDXD     LEA     SANDW,A1
                JMP     DSRCDDEST                              
IFANDWAIXD    LEA     SANDW,A1
                JMP     AISRCDDEST                
IFANDWIXD     LEA     SANDW,A1
                JMP     ISRCDDEST  
IFANDWAAXD    LEA     SANDW,A1
                JMP     AASRCDDEST                
IFANDWPRXD    LEA     SANDW,A1
                JMP     PRSRCDDEST                
IFANDWPOXD    LEA     SANDW,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFANDWDXAI    LEA     SANDW,A1
                JMP     DSRCADEST                

*abs addr dest
IFANDWDXAA    LEA     SANDW,A1
                JMP     DSRCAADEST                

*pre decr dest
IFANDWDXPR    LEA     SANDW,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFANDWDXPO    LEA     SANDW,A1
                JMP     DSRCPODEST   
                
**ANDL          

*data reg dest
IFANDLDXD     LEA     SANDL,A1
                JMP     DSRCDDEST                               
IFANDLAIXD    LEA     SANDL,A1
                JMP     AISRCDDEST                
IFANDLIXD     LEA     SANDL,A1
                JMP     ISRCDDEST  
IFANDLAAXD    LEA     SANDL,A1
                JMP     AASRCDDEST                
IFANDLPRXD    LEA     SANDL,A1
                JMP     PRSRCDDEST                
IFANDLPOXD    LEA     SANDL,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFANDLDXAI    LEA     SANDL,A1
                JMP     DSRCADEST                

*abs addr dest
IFANDLDXAA    LEA     SANDL,A1
                JMP     DSRCAADEST                

*pre decr dest
IFANDLDXPR    LEA     SANDL,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFANDLDXPO    LEA     SANDL,A1
                JMP     DSRCPODEST 

*---------------- OR Variants--------------*
**ORB
*data reg dest
IFORBDXD     LEA     SORB,A1
                JMP     DSRCDDEST                              
IFORBAIXD    LEA     SORB,A1
                JMP     AISRCDDEST                
IFORBIXD     LEA     SORB,A1
                JMP     ISRCDDEST  
IFORBAAXD    LEA     SORB,A1
                JMP     AASRCDDEST                
IFORBPRXD    LEA     SORB,A1
                JMP     PRSRCDDEST                
IFORBPOXD    LEA     SORB,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFORBDXAI    LEA     SORB,A1
                JMP     DSRCADEST                

*abs addr dest
IFORBDXAA    LEA     SORB,A1
                JMP     DSRCAADEST                

*pre decr dest
IFORBDXPR    LEA     SORB,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFORBDXPO    LEA     SORB,A1
                JMP     DSRCPODEST                                          
                
**ORW
*data reg dest
IFORWDXD     LEA     SORW,A1
                JMP     DSRCDDEST                              
IFORWAIXD    LEA     SORW,A1
                JMP     AISRCDDEST                
IFORWIXD     LEA     SORW,A1
                JMP     ISRCDDEST  
IFORWAAXD    LEA     SORW,A1
                JMP     AASRCDDEST                
IFORWPRXD    LEA     SORW,A1
                JMP     PRSRCDDEST                
IFORWPOXD    LEA     SORW,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFORWDXAI    LEA     SORW,A1
                JMP     DSRCADEST                

*abs addr dest
IFORWDXAA    LEA     SORW,A1
                JMP     DSRCAADEST                

*pre decr dest
IFORWDXPR    LEA     SORW,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFORWDXPO    LEA     SORW,A1
                JMP     DSRCPODEST   
                
**ORL          

*data reg dest
IFORLDXD     LEA     SORL,A1
                JMP     DSRCDDEST                               
IFORLAIXD    LEA     SORL,A1
                JMP     AISRCDDEST                
IFORLIXD     LEA     SORL,A1
                JMP     ISRCDDEST  
IFORLAAXD    LEA     SORL,A1
                JMP     AASRCDDEST                
IFORLPRXD    LEA     SORL,A1
                JMP     PRSRCDDEST                
IFORLPOXD    LEA     SORL,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFORLDXAI    LEA     SORL,A1
                JMP     DSRCADEST                

*abs addr dest
IFORLDXAA    LEA     SORL,A1
                JMP     DSRCAADEST                

*pre decr dest
IFORLDXPR    LEA     SORL,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFORLDXPO    LEA     SORL,A1
                JMP     DSRCPODEST 
                
*---------------- JSR Variants-------------*
*ea src
IFJSREA         LEA     SJSR,A1
                JMP     EASRC    

IFJSRAXAI       LEA     SJSR,A1
                JMP     EASRCAI  

*---------------- RTS Variants-------------*
IFRTS           LEA     SRTS,A1
                BSR     PRINTSTR
                JMP     CONTINUE

*---------------- Bcc Variants-------------*
IFBRA           LEA     SBRA,A1
                JMP     EASRC    
                
IFBGT           LEA     SBGT,A1
                JMP     EASRC    

IFBLE           LEA     SBLE,A1
                JMP     EASRC    

IFBEQ           LEA     SBEQ,A1
                JMP     EASRC                    

*---------------- ASL Variants--------------*
**ASL                 

*effective addresses
IFASLEA         LEA     SASL,A1
                JMP     EASRC    

IFASLEAXAI      LEA     SASL,A1
                JMP     EASRCAI

IFASLEAXPR      LEA     SASL,A1
                JMP     EASRCPR 

IFASLEAXPO      LEA     SASL,A1
                JMP     EASRCPO 

**ASL.B
*data reg dest
IFASLBDXD       LEA     SASLB,A1
                JMP     DSRCDDEST  
IFASLBIXD       LEA     SASLB,A1
                JMP     ISRCDDEST                  

**ASL.W
*data reg dest
IFASLWDXD       LEA     SASLW,A1
                JMP     DSRCDDEST  
IFASLWIXD       LEA     SASLW,A1
                JMP     ISRCDDEST                 

**ASL.L
*data reg dest
IFASLLDXD       LEA     SASLL,A1
                JMP     DSRCDDEST  
IFASLLIXD       LEA     SASLL,A1
                JMP     ISRCDDEST                 

*---------------- ASR Variants--------------*
**ASR                 

*effective addresses
IFASREA         LEA     SASR,A1
                JMP     EASRC    

IFASREAXAI      LEA     SASR,A1
                JMP     EASRCAI

IFASREAXPR      LEA     SASR,A1
                JMP     EASRCPR 

IFASREAXPO      LEA     SASR,A1
                JMP     EASRCPO 

**ASR.B
*data reg dest
IFASRBDXD       LEA     SASRB,A1
                JMP     DSRCDDEST  
IFASRBIXD       LEA     SASRB,A1
                JMP     ISRCDDEST                 


**ASR.W
*data reg dest
IFASRWDXD       LEA     SASRW,A1
                JMP     DSRCDDEST  
IFASRWIXD       LEA     SASRW,A1
                JMP     ISRCDDEST                 

**ASR.L
*data reg dest
IFASRLDXD       LEA     SASRL,A1
                JMP     DSRCDDEST  
IFASRLIXD       LEA     SASRL,A1
                JMP     ISRCDDEST                 

*--------------- LSL Variants--------------*
**LSL                

*effective addresses
IFLSLEA         LEA     SLSL,A1
                JMP     EASRC    

IFLSLEAXAI      LEA     SLSL,A1
                JMP     EASRCAI

IFLSLEAXPR      LEA     SLSL,A1
                JMP     EASRCPR 

IFLSLEAXPO      LEA     SLSL,A1
                JMP     EASRCPO 

**LSL.B
*data reg dest
IFLSLBDXD       LEA     SLSLB,A1
                JMP     DSRCDDEST  
IFLSLBIXD       LEA     SLSLB,A1
                JMP     ISRCDDEST                 

**LSL.W
*data reg dest
IFLSLWDXD       LEA     SLSLW,A1
                JMP     DSRCDDEST  
IFLSLWIXD       LEA     SLSLW,A1
                JMP     ISRCDDEST                 

**LSL.L
*data reg dest
IFLSLLDXD       LEA     SLSLL,A1
                JMP     DSRCDDEST  
IFLSLLIXD       LEA     SLSLL,A1
                JMP     ISRCDDEST                 

*--------------- LSR Variants--------------*
**LSR               

*effective addresses
IFLSREA         LEA     SLSR,A1
                JMP     EASRC    

IFLSREAXAI      LEA     SLSR,A1
                JMP     EASRCAI

IFLSREAXPR      LEA     SLSR,A1
                JMP     EASRCPR 

IFLSREAXPO      LEA     SLSR,A1
                JMP     EASRCPO 

**LSR.B
*data reg dest
IFLSRBDXD       LEA     SLSRB,A1
                JMP     DSRCDDEST  
IFLSRBIXD       LEA     SLSRB,A1
                JMP     ISRCDDEST                 

**LSR.W
*data reg dest
IFLSRWDXD       LEA     SLSRW,A1
                JMP     DSRCDDEST  
IFLSRWIXD       LEA     SLSRW,A1
                JMP     ISRCDDEST                 

**LSR.L
*data reg dest
IFLSRLDXD       LEA     SLSRL,A1
                JMP     DSRCDDEST  
IFLSRLIXD       LEA     SLSRL,A1
                JMP     ISRCDDEST                 

*--------------- ROL Variants--------------*
**ROL              

*effective addresses
IFROLEA         LEA     SROL,A1
                JMP     EASRC    

IFROLEAXAI      LEA     SROL,A1
                JMP     EASRCAI

IFROLEAXPR      LEA     SROL,A1
                JMP     EASRCPR 

IFROLEAXPO      LEA     SROL,A1
                JMP     EASRCPO 

**ROL.B
*data reg dest
IFROLBDXD       LEA     SROLB,A1
                JMP     DSRCDDEST  
IFROLBIXD       LEA     SROLB,A1
                JMP     ISRCDDEST                 

**ROL.W
*data reg dest
IFROLWDXD       LEA     SROLW,A1
                JMP     DSRCDDEST  
IFROLWIXD       LEA     SROLW,A1
                JMP     ISRCDDEST                  

**ROL.L
*data reg dest
IFROLLDXD       LEA     SROLL,A1
                JMP     DSRCDDEST  
IFROLLIXD       LEA     SROLL,A1
                JMP     ISRCDDEST                 

*--------------- ROR Variants--------------*
**ROR                

*effective addresses
IFROREA         LEA     SROR,A1
                JMP     EASRC    

IFROREAXAI      LEA     SROR,A1
                JMP     EASRCAI

IFROREAXPR      LEA     SROR,A1
                JMP     EASRCPR 

IFROREAXPO      LEA     SROR,A1
                JMP     EASRCPO 

**ROR.B
*data reg dest
IFRORBDXD       LEA     SRORB,A1
                JMP     DSRCDDEST  
IFRORBIXD       LEA     SRORB,A1
                JMP     ISRCDDEST                 

**ROR.W
*data reg dest
IFRORWDXD       LEA     SRORW,A1
                JMP     DSRCDDEST  
IFRORWIXD       LEA     SRORW,A1
                JMP     ISRCDDEST                 

**ROR.L
*data reg dest
IFRORLDXD       LEA     SRORL,A1
                JMP     DSRCDDEST  
IFRORLIXD       LEA     SRORL,A1
                JMP     ISRCDDEST                 
               
*----------------Bad Data-------------*             
IFBADDATA       LEA     DATA,A1
                BSR     PRINTSTR
                BSR     PRINTAASRC
                BSR     PRINTCRLF
                JMP     CONTINUE  
                
IFINVADDRMODE   LEA     OPCODE,A1
                BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     INVADDR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE                 

*-------------------------------------------*
*----------------OPERAND DATA----------------*
*-------------------------------------------*                 
*guess this is now a section now
*i was hoping for the one buggy EA but nope
*effective addresses
EASRC           BSR     PRINTSTR *EA SPORTS ITS IN THE GAME
                BSR     PRINTAASRC
                JMP     CONTINUE
                
EASRCAI         BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                JMP     CONTINUE 

EASRCPR         BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR 
                JMP     CONTINUE

EASRCPO         BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                JMP     CONTINUE 

EASRCD          BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                JMP     CONTINUE    

*----------------Data Register Dest-----------*

*data reg to data reg
DSRCDDEST       BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to data reg               
ASRCDDEST       BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to data reg 
AISRCDDEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to data reg
ISRCDDEST       BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to data reg                
AASRCDDEST      BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to data reg
PRSRCDDEST      BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to data reg
POSRCDDEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*----------------Address Register Dest-----------* 
               
*data reg to addr reg
DSRCADEST       BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to addr reg               
ASRCADEST       BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to addr reg 
AISRCADEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to addr reg
ISRCADEST       BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to addr reg                
AASRCADEST      BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to addr reg
PRSRCADEST      BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to addr reg
POSRCADEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE      

*----Address Register Indirect Dest----------* 
               
*data reg to addr indirect
DSRCAIDEST      BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to addr indirect
ASRCAIDEST      BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to addr indirect
AISRCAIDEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to addr indirect
ISRCAIDEST      BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to addr indirect
AASRCAIDEST     BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to addr indirect
PRSRCAIDEST     BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to addr indirect
POSRCAIDEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE        

*----Immediate data Dest----------* 
               
*data reg to immediate
DSRCIDEST       BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to immediate
ASRCIDEST       BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to immediate
AISRCIDEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to immediate
ISRCIDEST       BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to immediate
AASRCIDEST      BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to immediate
PRSRCIDEST      BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to immediate
POSRCIDEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE  

*----Absolute Addressing Dest--------* 
    
*data reg to abs addr
DSRCAADEST      BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to abs addr              
ASRCAADEST      BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to abs addr
AISRCAADEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to abs addr
ISRCAADEST      BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to abs addr              
AASRCAADEST     BSR     PRINTSTR
                BSR     PRINTAASRC
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to abs addr
PRSRCAADEST     BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to abs addr
POSRCAADEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE          
   
*----Address Pre Decrement Dest-------* 
               
*data reg to pre decr
DSRCPRDEST      BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to pre decr
ASRCPRDEST      BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to pre decr
AISRCPRDEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to pre decr
ISRCPRDEST      BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to pre decr
AASRCPRDEST     BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to pre decr
PRSRCPRDEST     BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to pre decr
POSRCPRDEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*----Address Post Increment Dest----------* 
               
*data reg to post incre
DSRCPODEST      BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to post incre
ASRCPODEST      BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to post incre
AISRCPODEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to post incre
ISRCPODEST      BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to post incre
AASRCPODEST     BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to post incre
PRSRCPODEST     BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to post incre
POSRCPODEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   
             
*----------------I/O Helpers----------------*

*used for w/l addresses (since they can't be displayed in decimal)                
PRINTAASRC      LEA     AASRC,A1
                BSR     PRINTSTR
                MOVE.B  #16,D2
                MOVE.B  #15,D0
                MOVE.L  D6,D1
                TRAP    #15
                RTS                

*used for w/l addresses (since they can't be displayed in decimal) 
PRINTAADST      LEA     AADEST,A1
                BSR     PRINTSTR
                MOVE.B  #16,D2
                MOVE.B  #15,D0
                MOVE.L  D7,D1
                TRAP    #15
                RTS 
                
*prints first op value w/ string
FIRSTOP         MOVE.L  D6,D1
                MOVE.B  #17,D0
                TRAP    #15
                RTS

*prints second op value w/ string             
SECONDOP        MOVE.L  D7,D1
                MOVE.B  #17,D0
                TRAP    #15
                RTS
                

PRINTCRLF       LEA     CRLF,A1
PRINTSTR        MOVE.B  #14,D0
                TRAP    #15
                RTS
                
NEXTPAGE        MOVE.W   #31,A4 *next page wooo
                LEA      ENTPAGE,A1
                BSR      PRINTSTR
                MOVE.B   #5,D0 *get a char (in this case, enter key)
                TRAP     #15
                BSR      FLUSH
                JMP      CONTINUE
                             
FLUSH           MOVE.B   #11,D0
                MOVE.W   #$FF00,D1 *flush print screen
                TRAP     #15
                RTS               
               
PRINTZEROES     MOVE.L   A6,D2
                AND.L    D3,D2
                NOP
                CMP.L    #0,D2
                BNE      FINPRINTZEROES
                ROR.L    #4,D3
                CMP.L    #$F0000000,D3
                BEQ      FINPRINTZEROES
                MOVE.B   #6,D0
                MOVE.B   #$30,D1 *0
                TRAP     #15
                BRA      PRINTZEROES

FINPRINTZEROES  RTS

*-------------------------------------------*
*----------------STRING DATA----------------*
*-------------------------------------------*

CR      EQU     $0D
LF      EQU     $0A

TB      DC.B    $09,0
CRLF    DC.B    CR,LF,0

DOLLAR  DC.B    '$',0
DATA    DC.B    'DATA',0
OPCODE  DC.B    'OPCODE',0
INVADDR DC.B    ' INVALID ADDRESSING MODE',0

WELCOME DC.B    'Team Rocket Lake Presents...',CR,LF,'Our CSS 422 68k Disassembler!',CR,LF,CR,LF,0
ENTADDR1 DC.B   'Enter the lower bound long address in hexadecimal (example: 100A,11BC88): ',0
ENTADDR2 DC.B   'Enter the upper bound long address in hexadecimal (example: 100A,11BC88): ',0
ENTPAGE  DC.B   '----------NEXT PAGE--------->',0
STARTAGAIN DC.B 'Disassembly complete. Do you wish to continue? Type y or n.',0
ERRMSG   DC.B 'Input error. Please follow the format as described.',CR,LF,0

DSRC    DC.B    ' D',0
ASRC    DC.B    ' A',0
ISRC    DC.B    ' #',0
PRSRC   DC.B    ' -(A',0
AISRC   DC.B    ' (A',0
AASRC   DC.B     ' $',0

DDEST   DC.B    ',D',0
ADEST   DC.B    ',A',0
IDEST   DC.B    ',#',0
AADEST  DC.B    ',$',0
PRDEST  DC.B    ',-(A',0
PODEST  DC.B    ')+',0
AIDEST  DC.B    ',(A',0
CLPAR   DC.B    ')',0     

*---------------- NOP Variants-------------*
SNOP    DC.B    'NOP',0 *snop.

*---------------- MOVE Variants-------------*
SMOVEB DC.B 'MOVE.B',0
SMOVEW DC.B 'MOVE.W',0
SMOVEL DC.B 'MOVE.L',0

*---------------- MOVEA Variants-------------*
*Data reg
SMOVEAW DC.B 'MOVEA.W',0
SMOVEAL DC.B 'MOVEA.L',0

*--------------MOVEQ VARIANTS---------------*
*only works with data registers and longs *
SMOVEQ DC.B 'MOVEQ',0

*--------------ADD VARIANTS---------------*
SADDB DC.B 'ADD.B',0
SADDW DC.B 'ADD.W',0
SADDL DC.B 'ADD.L',0

*--------------ADDA VARIANTS---------------*
SADDAW DC.B 'ADDA.W',0
SADDAL DC.B 'ADDA.L',0

*--------------ADDQ VARIANTS---------------*
*only value for immidiate data to a location*
SADDQB DC.B 'ADDQ.B',0
SADDQW DC.B 'ADDQ.W',0
SADDQL DC.B 'ADDQ.L',0

*--------------------SUB VARIANTS-----------------------------*
SSUBB DC.B 'SUB.B',0
SSUBW DC.B 'SUB.W',0
SSUBL DC.B 'SUB.L',0

*---------------- LEA Variants-------------*
*LEA IS ONLY VALID FOR LONG WORD, THEREFORE DIDN'T SPECIFY IN THE CONSTANT NAME*
SLEA DC.B 'LEA',0

**---------------- NOT Variants-------------*
SNOTB DC.B 'NOT.B',0
SNOTW DC.B 'NOT.W',0
SNOTL DC.B 'NOT.L',0

**---------------- AND Variants-------------*
SANDB DC.B 'AND.B',0
SANDW DC.B 'AND.W',0
SANDL DC.B 'AND.L',0

**---------------- OR Variants--------------*
SORB DC.B 'OR.B',0
SORW DC.B 'OR.W',0
SORL DC.B 'OR.L',0

*---------------- JSR Variants-------------*
*NO SIZE* 
SJSR DC.B 'JSR',0

*---------------- RTS Variants-------------*
SRTS DC.B 'RTS',0

*---------------- Bcc Variants-------------*
SBGT  DC.B 'BGT',0
SBLE  DC.B 'BLE',0
SBEQ  DC.B 'BEQ',0

SBRA  DC.B 'BRA',0

*---------------- ASL Variants--------------*
SASL  DC.B 'ASL',0
SASLB DC.B 'ASL.B',0
SASLW DC.B 'ASL.W',0
SASLL DC.B 'ASL.L',0

*---------------- ASR Variants--------------*
SASR  DC.B 'ASR',0
SASRB DC.B 'ASR.B',0
SASRW DC.B 'ASR.W',0
SASRL DC.B 'ASR.L',0

*--------------- LSL Variants--------------*
SLSL  DC.B 'LSL',0
SLSLB DC.B 'LSL.B',0
SLSLW DC.B 'LSL.W',0
SLSLL DC.B 'LSL.L',0

*--------------- LSR Variants--------------*
SLSR  DC.B 'LSR',0
SLSRB DC.B 'LSR.B',0
SLSRW DC.B 'LSR.W',0
SLSRL DC.B 'LSR.L',0

*--------------- ROL Variants--------------*
SROL  DC.B 'ROL',0
SROLB DC.B 'ROL.B',0
SROLW DC.B 'ROL.W',0
SROLL DC.B 'ROL.L',0

*--------------- ROR Variants--------------*
SROR  DC.B 'ROR',0
SRORB DC.B 'ROR.B',0
SRORW DC.B 'ROR.W',0
SRORL DC.B 'ROR.L',0


    END START
















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
