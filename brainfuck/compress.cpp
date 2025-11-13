#include <iostream>
#include <fstream>
#include <stack>
using namespace std;

int compressed[300000];
char instructions[300000];

int main(){
    ifstream in("test.b");
    stack<int> S;
    string a;
    string rdi = "";
    while(in >> a){
        rdi+=a;
        rdi+=' ';
    }
    string copy = "";
    for(auto g:rdi){
        if(g=='>' || g=='<' || g=='+' || g=='-' || g=='[' || g==']' || g==',' || g=='.'){
            copy += g;
        }
        else{
            copy+=' ';
        }
    }
    int counter  = 0;
    int it = 0;
    for(int i = 0;i<copy.size()-1;i++){
        if(copy[i]=='>'){
            counter++;
            if(copy[i+1]==copy[i]){
                continue;
            }
            else{
                compressed[it]=counter;
                instructions[it]='>';
                it++;
                counter = 0;
            }
        }
        else if(copy[i]=='<'){
            counter--;
            if(copy[i+1]==copy[i]){
                continue;
            }
            else{
                compressed[it]=counter;
                instructions[it]='>';
                it++;
                counter = 0;
            }
        }
        else if(copy[i]=='+'){
            counter++;
            if(copy[i+1]==copy[i]){
                continue;
            }
            else{
                compressed[it]=counter;
                instructions[it]='+';
                it++;
                counter = 0;
            }
        }
        else if(copy[i]=='-'){
            counter--;
            if(copy[i+1]==copy[i]){
                continue;
            }
            else{
                compressed[it]=counter;
                instructions[it]='+';
                it++;
                counter = 0;
            }
        }
        else if(copy[i]==','){
            compressed[it]=1;
            instructions[it]=',';
            it++;
            counter = 0;
        }
        else if(copy[i]=='.'){
            compressed[it]=1;
            instructions[it]='.';
            it++;
            counter = 0;
        }
        else if(copy[i]=='['){
            S.push(it);
            instructions[it] = '[';
            it++;
            counter = 0;
        }
        else if(copy[i]==']'){
            int it2 = S.top();
            S.pop();
            compressed[it] = it2;
            compressed[it2] = it;
            instructions[it] = ']' ;
            it++;
            counter = 0;
        }
        else{
            continue;
        }
    }
    /*
    for(int i = 0;i<it;i++){
        cout << "Insstruction : " << instructions[i] << " ||| " << compressed[i] << endl;
    }*/
    
    int it2 = 0;
    int accu = 0;
    for(int i = 0;i<it;i++){
        if(i+5>=it){
            //cout << "NIe ma miejsca wiec przepisuje| " << instructions[i] << endl;;
            instructions[it2] = instructions[i];
            compressed[it2] = compressed[i];
            if(instructions[i]==']' || instructions[i]=='['){
                compressed[it2]-=accu;
            }
            it2++;
            continue;
        }
        if(instructions[i]=='[' && instructions[i+1]=='+' && instructions[i+2]=='>' && instructions[i+3]=='+' && instructions[i+4]=='>' && instructions[i+5]==']'){
                if(compressed[i+2]+compressed[i+4]==0 && compressed[i+1]==-1 && compressed[i+3]==1){
                    //cout << "Pisze M | " << accu << endl;
                    instructions[it2] = 'M';
                    compressed[it2] = compressed[i+2];
                    i+=5;
                    it2++;
                    accu+=5;
                    //cout << "Pisze M | " << instructions[i] << endl;
                    continue;
                }
                else{
                    //cout << "Przepisuje | " << instructions[i] << endl;
                    
                    instructions[it2] = instructions[i];
                    compressed[it2] = compressed[i];
                    if(instructions[i]==']' || instructions[i]=='['){
                        compressed[it2]-=accu;
                    }
                    
                    it2++;
                    continue;
                }
        }
        else{
            //cout << "Przepisuje | " << instructions[i] << endl;
            instructions[it2] = instructions[i];
            compressed[it2] = compressed[it2];
            if(instructions[i]==']' || instructions[i]=='['){

                compressed[it2]-=accu;
            }
            it2++;
            continue;
        }
    }
    for(int i = 0;i<it2;i++){
        cout << "Insstruction : " << instructions[i] << " ||| " << compressed[i] << endl;
    }


}