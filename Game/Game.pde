import java.util.*;

GameClass game;
boolean mouseDrag, mousePress, mouseRelease, paused = false;
ArrayList<Station> a = new ArrayList<Station>();
int counter;

void setup() {
  fullScreen();
  game = new GameClass(new Map("../Maps/Map-London.png"));
  paused = false;
  //frameRate(30);
  counter = 0;
}

void draw() {
  game.run();
  if (! paused)
    this.game.proc += 1;
  else {
    fill(0, 10);
    rect(0, 0, 1920, 1080);
  }
  fill(0);
  textSize(32);
  text(game.proc + "", 90, 90);
  text(counter + "", width - 90, 90);
}

void keyPressed() {
  if (key == 27) {
    key = 32;
  }
  if (key == 32) {
    paused = ! paused;
  }
}

void mouseDragged() {
  mouseDrag = true;
  mouseRelease = false;
}

void mousePressed() {
  mousePress = true;
  mouseRelease = false;
}

void mouseReleased() {
  mouseDrag = false;
  mousePress = false;
  mouseRelease = true;
  game.addRoute(a);
  a.clear();
}



class GameClass {

  ArrayList<Integer> colors;
  ArrayList<Route> routes;
  ArrayList<Station> stations;
  boolean paused;
  int numColors, numStations, proc;
  Map map;
  String[] shapes = new String[] {"Circle", "Square", "Triangle"};

  GameClass() {
    this.colors = new ArrayList<Integer>();
    colors.add(color(236, 52, 46));
    colors.add(color(0, 145, 60));
    colors.add(color(184, 51, 172));
    colors.add(color(40, 80, 172));
    colors.add(color(253, 99, 25));
    colors.add(color(250, 202, 10));
    colors.add(color(152, 101, 52));
    this.numStations = 0;
    this.paused = false;
    this.proc = 0;
    this.stations = new ArrayList<Station>();
    int i = 1;
    while (i > 0) {
      if (addStation(new Station((int) random(1, 16) * width / 16, (int) random(1, 9) * height / 9, shapes[(int) random(0, 3)], numStations))) {
        i -= 1;
      }
    }
  }

  GameClass(Map map) {
    this.colors = new ArrayList<Integer>();
    colors.add(color(236, 52, 46));
    colors.add(color(0, 145, 60));
    colors.add(color(184, 51, 172));
    colors.add(color(40, 80, 172));
    colors.add(color(253, 99, 25));
    colors.add(color(250, 202, 10));
    colors.add(color(152, 101, 52));
    this.map = map;
    this.numStations = 0;
    this.paused = false;
    this.proc = 0;
    this.routes = new ArrayList<Route>();
    this.stations = new ArrayList<Station>();
    int i = 1;
    while (i > 0) {
      if (addStation(new Station((int) random(1, 16) * width / 16, (int) random(1, 9) * height / 9, shapes[(int) random(0, 3)], numStations))) {
        i -= 1;
      }
    }
  }

  void addRoute(ArrayList<Station> stations) {
    if (colors.size() == 0)
      return;
    if (stations.size() <= 1)
      return;
    Route route = new Route(stations, colors.remove(0));
    route.metros.add(new Metro(route));
    routes.add(route);
    stations.clear();
  }

  boolean addStation(Station station) {
    if (map.image.get(station.x, station.y) == color(224)) {
      stations.add(station);
      numStations += 1;
      map.image.set(station.x, station.y, color(0));
      return true;
    }
    return false;
  }

  void run() {
    game.map.draw(width / 2, height / 2);
    for (Route route : routes)
      route.draw();
    boolean b = false;
    if (proc % 1000 == 0 && ! b)
      b = addStation(new Station((int) random(1, 16) * width / 16, (int) random(1, 9) * height / 9, shapes[(int) random(0, 3)], numStations));
    if (proc % 500 == 0) {
      int i = (int) random(0, stations.size()), j = i;
      while (j == i)
        j = (int) random(0, stations.size());
      stations.get(i).addPassenger(new Passenger(stations.get(i), stations.get(j)));
    }
    for (Route route : routes) {
      route.draw();
      for (Metro metro : route.metros) {
        metro.move();
        metro.draw();
      }
    }
    for (Station station : stations) {
      if (mousePress) {
        if (mouseX > station.x - 45 && mouseX < station.x + 45 &&
          mouseY > station.y - 45 && mouseY < station.y + 45) {
          PImage ripple = loadImage(station.filename);
          ripple.resize(60, 60);
          tint(255);
          imageMode(CENTER);
          image(ripple, station.x, station.y);
        }
      }
      if (station.selected && a.indexOf(station) == -1)
        a.add(station);
      if (mousePress) {
        if (mouseX > station.x - 45 && mouseX < station.x + 45 &&
            mouseY > station.y - 45 && mouseY < station.y + 45) {
          station.selected = true;
        }
      }
      if (mouseRelease)
        station.selected = false;
      station.draw();
      for (int i = 0, j = 45; i < station.passengers.size(); i += 1, j += 30)
        station.passengers.get(i).draw(station.x + j, station.y);
    }
  }

}



class Map {

  PImage image;
  String filename;

  Map(String filename) {
    this.filename = filename;
    this.image = loadImage(this.filename);
  }

  void draw(int x, int y) {
    imageMode(CENTER);
    image(image, x, y);
  }

}



class Metro {

  ArrayList<Metro> cars;
  ArrayList<Passenger> passengers;
  boolean selected;
  int direction, speed, timer, x, y;
  PImage image;
  Route route;
  Station next;

  Metro(Route route) {
    this.direction = 1;
    this.next = route.stations.get(1);
    this.passengers = new ArrayList<Passenger>(0);
    this.route = route;
    this.selected = false;
    this.speed = 3;
    this.timer = -1;
    this.x = route.stations.get(0).x;
    this.y = route.stations.get(0).y;
  }

  void load() {
    while (x == next.x && y == next.y && next.passengers.size() > 0 && passengers.size() < 6) {
      passengers.add(next.passengers.remove(0));
    }
  }

  void unload() {
    int i = 0;
    while (x == next.x && y == next.y && i < passengers.size()) {
      if (passengers.get(i).destination.id == next.id) {
        passengers.remove(i);
        counter += 1;
      }
      else
        i += 1;
    }
  }

  Station getNext() {
      if (route.stations.indexOf(next) == 0 ||
      route.stations.indexOf(next) == route.stations.size() - 1);
      direction *= -1;
      timer = 100;
      try {
          next = route.stations.get(route.stations.indexOf(next) + direction);
      }
      catch (IndexOutOfBoundsException e) { };
      return next;
  }

  void move() {
      unload();
      load();
      if (x == next.x && y == next.y)
      getNext();
      if (abs((x - speed) - next.x) < abs(x - next.x) && timer < 0)
      x -= speed;
      if (abs((x + speed) - next.x) < abs(x - next.x) && timer < 0)
      x += speed;
      if (abs((y - speed) - next.y) < abs(y - next.y) && timer < 0)
      y -= speed;
      if (abs((y + speed) - next.y) < abs(y - next.y) && timer < 0)
      y += speed;
      timer -= 1;
  }

  void draw() {
    fill(route.Color);
    rectMode(CENTER);
    rect(x, y, 60, 30);
    for (int i = 0, j = -24; i < 3 && i < passengers.size(); i += 1, j += 24)
    passengers.get(i).draw(x + j, y - 6);
    for (int k = 3, l = -24; k < 6 && k < passengers.size(); k += 1, l += 24)
    passengers.get(k).draw(x + l, y + 18);
    fill(0);
    textMode(CENTER);
    text(route.stations.indexOf(next), x, y);
  }

}

class Trace extends Metro{
  
  boolean active = true;
  
  Trace(Route route){
  super(route);
  beginShape(); 
  }
  
  void makePoint(){
   curveVertex(x,y);
   if ((dist(x,y,station.x,station.y) < 10)){
     endShape();
     active = false;
  }
  
}
}

class Passenger {

  int patience;
  PImage image;
  Route path;
  String filename, shape;
  Station current, destination;

  Passenger() {
    this.patience = 10000;
  }

  Passenger(Station destination) {
    this.destination = destination;
    this.filename = "../Reference/Passenger-" + this.destination.shape + ".png";
    this.image = loadImage(filename);
  }

  Passenger(Station current, Station destination) {
    this.current = current;
    this.destination = destination;
    this.filename = "../Reference/Passenger-" + this.destination.shape + ".png";
    this.image = loadImage(filename);
  }

  /*
  void findPath() {
    ArrayList<Station> a = new ArrayList<Station>();
    Stack<Station> stack = new Stack();
    Station temp = current;
    stack.add(temp);
    while (stack.size() > 0) {
      temp = stack.pop();
      if (temp.id == destination.id) {
        a.add(temp);
        return;
      }
    }
  }
  */

  void draw(int x, int y) {
    imageMode(CENTER);
    image(image, x, y);
  }

}




class Route {

  ArrayList<Station> stations;
  ArrayList<Metro> metros;
  int Color;
  boolean Active;

  Route(ArrayList<Station> stations, int Color) {
    this.Color = Color;
    this.metros = new ArrayList<Metro>();
    this.stations = stations;
  }

  //psuedo code for better understanding how the route class should work based on diagram
  //we should also try to find a way to link passengers with routes to keep track of position
  /*
  isRoute(){
    for(int i = 0; i < stations.size() - 1; i+= 1){ //traverse through the stations to check for the same id
      if (passenger.current.id != station.get(i).id){ //if the current id doesn't match with the id of the station move to next station
        passenger.(current + 1).id;
      }
      if (passenger.destination.id == id){ //once reached to the same shaped station, go back to the following route and put all the stations followed into arraylist
        stations.add(passenger.(current - 1).id;
      }
    }
  }
  */
  
  void draw() {
    for (float i = 0; i < stations.size() - 1; i += 1) {
      stroke(Color);
      strokeWeight(10);
      line(stations.get((int)i).x, stations.get((int)i).y, stations.get((int)i + 1).x, stations.get((int)i + 1).y);
  }
}
}
  
  /*
   ArrayList<Station> getPath(GameClass game,Station current, Station destination){
    sequence = new Arraylist<Station>();
    ArrayList<Station> q = new ArrayList<Station>();
    q.add(current);
    while(q.size() > 0){
      ArrayList<Station> temp = game.stations;
      Station s = temp.remove(0);
      if (s.x == destination.x && s.y == destination.y){
        q.add(s);
        while(s.get(current - 1) != null){
          destination.set(station.x, station.y, s.get(Passenger,current - 1));
          s = s.get(Passenger.current - 1);
        }

      }
    }
  }
  */

class Station {

  ArrayList<Passenger> passengers;
  boolean selected;
  int x, y, id;
  PImage image;
  String filename, shape;

  Station(int x, int y, String shape, int id) {
    this.filename = "../Reference/Station-" + shape + ".png";
    this.id = id;
    this.image = loadImage(this.filename);
    this.passengers = new ArrayList<Passenger>();
    this.selected = false;
    this.shape = shape;
    this.x = x;
    this.y = y;
  }

  boolean addPassenger(Passenger passenger) {
    if (passenger.destination.id != id) {
      passengers.add(passenger);
      return true;
    }
    return false;
  }

  void draw() {
      imageMode(CENTER);
      image(image, x, y);
  }

}