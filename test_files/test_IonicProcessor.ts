import { Component } from '@angular/core';

@Component({
  selector: 'app-home',
  template: '<h1>{{message}}</h1>'
})
export class HomePage {
  message: string = 'Hello Ionic';
  
  constructor() {
    console.log(this.message);
  }
}