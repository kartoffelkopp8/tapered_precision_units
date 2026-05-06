#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <universal/number/posit/posit.hpp>

using namespace sw::universal;
using namespace std;

#define C_N 8
#define C_ES 2
#define CONTAINER uint8_t


string get_hex(posit<C_N, C_ES, CONTAINER> num){
  return (to_hex(num.bits(), false)).substr(2);
}

void write_special_cases(ofstream *file, posit<C_N, C_ES, CONTAINER> op0, posit<C_N, C_ES, CONTAINER> op1){
  cout << "Generating Special cases..." << endl;
  // 0+0
  op0.setbits(0);
  op1.setbits(0);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;

  //0+x
  op0.setbits(0);
  op1.setbits(1.2);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;
  // nar + x
  op0.setbits(128);
  op1.setbits(4);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;

  // 1 -1 
  op0.setbits(1);
  op1.setbits(-1);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;

  // check mapos rounding according to standard
  op0.setbits(128);
  op1.setbits(1);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;

  // check sign if negative bigger than 
  op0.setbits(-123);
  op1.setbits(1);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;

  // check special case (mantissa overflow -> rigthshift) wich made errors in the past
  op0.setbits(66);
  op1.setbits(67);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;

  op0.setbits(3);
  op1.setbits(3);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;

  op0.setbits(0x11);
  op1.setbits(0xD8);

  *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;
}

void write_random_cases(ofstream *file, posit<C_N, C_ES, CONTAINER> op0, posit<C_N, C_ES, CONTAINER> op1, unsigned long num){
  cout << "Generating " << num << " Random Testcases\n";
  
  for(uint64_t i = 0; i < num; i++){
    unsigned long a = rand() % (1 << C_N);
    unsigned long b = rand() % (1 << C_N);

    op0.setbits(a);
    op1.setbits(b);

    *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;
  }
}

// CAREFULL!!!!! could take until heat death of the universe to test depending on bits
void write_all_cases(ofstream *file, posit<C_N, C_ES, CONTAINER> op0, posit<C_N, C_ES, CONTAINER> op1){
  cout << "Generating All possible Testvectors WARNING: Simulation can take a long time depending on Bitwidth\n";

  for(uint64_t i = 0; i < (1 << C_N); i++){
    for(uint64_t j = 0; j < (1 << C_N); j++){
      op0.setbits(i);
      op1.setbits(j);

      *file << get_hex(op0) << " " << get_hex(op1) << " " << get_hex(op0+op1) << endl;
    }
  }
}

int main(int argc, char *argv[]) {
    string usage = "USAGE: ./gen_testvectors <OPTION>\n"
                   "OPTIONS:\n"
                   "  (keine) / N  -> generate edgecases\n"
                   "  R <number>   -> generate number random cases and edge cases\n"
                   "  A            -> generate all possible vectors";
    int select = 0;  // Immer initialisieren!
    int rand_num = 10;

    if (argc == 1) {
        select = 0;  // Keine Argumente → edgecases
    }
    else if (argc >= 2) {
        string arg1 = argv[1];
        
        if (arg1 == "R") {
            if (argc == 3) {
                select = 1;
                rand_num = stoi(argv[2]);
            } else {
                select = 1;
            }
        }
        else if (arg1 == "A") {
            if (argc == 2) {
                select = 2;
                cout << "Setting: All possible testvectors\n";
            } else {
                cerr << "Error: too many arguments!\n";
                return 1;
            }
        }
        else if (arg1 == "N") {
            if (argc == 2) {
                select = 0;
                cout << "Setting: Only special cases\n";
            } else {
                cerr << "Error: too many arguments!\n";
                return 1;
            }
        }
        else {
            cerr << usage << endl;
            return 1;
        }
    }

    ofstream file("testvectors");
    if (!file.is_open()) {
        cerr << "error opening file 'testvectors'\n";
        return 1;
    }

    posit<C_N, C_ES, CONTAINER> op0, op1, exp;

    if (select == 0) {
        write_special_cases(&file, op0, op1);
    } else if (select == 1) {
        write_special_cases(&file, op0, op1);
        write_random_cases(&file, op0, op1, rand_num);
    } else if (select == 2) {
        write_all_cases(&file, op0, op1);
    }
    
    file.close();
    cout << "Done! Results in 'testvectors'" << endl;
    return 0;
}