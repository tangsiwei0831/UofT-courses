// CSC343, Introduction to Databases
// Department of Computer Science, University of Toronto

// This code is provided solely for the personal and private use of
// students taking the course CSC343 at the University of Toronto.
// Copying for purposes other than this use is expressly prohibited.
// All forms of distribution of this code, whether as given or with
// any changes, are expressly prohibited.

// Authors: Diane Horton and Marina Tawfik

// Copyright (c) 2020 Diane Horton and Marina Tawfik


import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class Assignment2 {
  
  // A connection to the database
  Connection connection;

  Assignment2() throws SQLException {
    try {
      Class.forName("org.postgresql.Driver");
    } catch  (ClassNotFoundException e) {
      e.printStackTrace();
    }
  }

  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to Library, public.
   *
   * @param  url       the url for the database
   * @param  username  the username to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
  public boolean connectDB(String url, String username, String password) {
    try {
      this.connection = DriverManager.getConnection(url, username, password);
      String setPath = "SET search_path TO Library, public;";
      PreparedStatement statement = this.connection.prepareStatement(setPath);
      statement.execute();
    } catch(SQLException se) {
      return false;
    }
    return true;
  }

  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
  public boolean disconnectDB() {
    if(connection != null) {
      try {
        connection.close();
      } catch (SQLException se) {
        return false;
      }
    }
    return true;
  }
   
  /**
   * Returns the titles of all holdings at the given library branch 
   * by any contributor with the given last name. 
   * If no matches are found, returns an empty list.
   * If two different holdings happen to have the same title, returns both
   * titles.
   * 
   * @param  lastName  the last name to search for. 
   * @param  branch    the unique code of the branch to search within. 
   * @return           a list containing the titles of the matched items.  
   */
  public ArrayList<String> search(String lastName, String branch) throws SQLException {
    ArrayList<String> res = new ArrayList<String>();
    String view1 = "CREATE VIEW cId AS" + " SELECT id" + "FROM Contributor" + "Where lastname = " + lastName + ";";
    PreparedStatement s1 = this.connection.prepareStatement(view1);
    s1.execute();

    String view2 = "CREATE VIEW holdId AS" + " SELECT holding" + "FROM HoldingContributor, cId" +
            "Where HoldingContributor.contributor = cId.id" + ";";
    PreparedStatement s2 = this.connection.prepareStatement(view2);
    s2.execute();

    String view3 = "CREATE VIEW answer AS" + " SELECT title" + "FROM Holding, holdId" +
            "Where Holding.id = holdId.holding" + ";";
    PreparedStatement s3 = this.connection.prepareStatement(view3);
    try {
      s3.execute();
      ResultSet result = s3.executeQuery();
      while (result.next()) {
        res.add(result.getString(1));
      }
    }catch(SQLException e){
        System.err.println("SQL Exception." + e.getMessage());
      }
    return res;

    }

    /**
     * Records a patron's registration for a specific event.
     * Returns True iff
     *  (1) the card number and event ID provided are both valid
     *  (2) This patron is not already registered for this event
     * Otherwise, returns False.
     *
     * @param  cardNumber  card number of the patron.
     * @param  eventID     id of the event.
     * @return true if the operation was successful
     *                     (as per the above criteria), and false otherwise.
     */
    public boolean register (String cardNumber,int eventID) throws SQLException {
      String view1 = "CREATE VIEW check1 AS" + " SELECT card_number" + "FROM Patron" +
              "Where card_number = " + cardNumber + ";";
      PreparedStatement s1 = this.connection.prepareStatement(view1);
      s1.execute();
      ArrayList<String> res1 = new ArrayList<String>();
      ResultSet result1 = s1.executeQuery();
      while (result1.next()) {
        res1.add(result1.getString(1));
      }
      if (res1.size() == 0) {
        return false;
      }


      String view2 = "CREATE VIEW check2 AS" + " SELECT id" + "FROM LibraryEvent" +
              "Where id = " + eventID + ";";
      PreparedStatement s2 = this.connection.prepareStatement(view2);
      s2.execute();
      List<Integer> res2 = new ArrayList<Integer>();
      ResultSet result2 = s2.executeQuery();
      while (result2.next()) {
        res2.add(result2.getInt(1));
      }
      if (res2.size() == 0) {
        return false;
      }

      String view3 = "CREATE VIEW check3 AS" + " SELECT patron, event" + "FROM EventSignUp" +
              "Where patron = " + cardNumber + "event = " + eventID + ";";
      PreparedStatement s3 = this.connection.prepareStatement(view3);
      s3.execute();
      List<String> res3 = new ArrayList<String>();
      ResultSet result3 = s3.executeQuery();
      while (result3.next()) {
        res3.add(result3.getString(1));
      }
      if (res3.size() == 0) {
        return false;
      } else {
        return true;
      }

    }

    /**
     * Records that a checked out library item was returned and returns
     * the fines incurred on that item.
     *
     * Does so by inserting a row in the Return table and updating the
     * LibraryCatalogue table to indicate the revised number of copies
     * available.
     *
     * Uses the same due date rules as the SQL queries.
     * The fines incurred are calculated as follows: for every day overdue
     * i.e. past the due date:
     *    books and audiobooks incurr a $0.50 charge
     *    other holding types incurr a $1.00 charge
     *
     * A return operation is considered successful iff:
     *    (1) The checkout id provided is valid.
     *    (2) A return has not already been recorded for this checkout
     *    (3) The number of available copies is less than the number of holdings
     * If the return operation is unsuccessful, the db instance should not
     * be modified at all.
     *
     * @param  checkout  id of the checkout
     * @return the amount of fines incurred if the return operation
     *                   was successful, -1 otherwise.
     */
    public double item_return (int checkout) throws SQLException {
      String view1 = "CREATE VIEW check1 AS" + " SELECT id" + "FROM Checkout" +
              "Where id = " + checkout + ";";
      PreparedStatement s1 = this.connection.prepareStatement(view1);
      s1.execute();
      List<Integer> res1 = new ArrayList<Integer>();
      ResultSet result1 = s1.executeQuery();
      while (result1.next()) {
        res1.add(result1.getInt(1));
      }
      if (res1.size() != 0) {
        String view2 = "CREATE VIEW check2 AS" + " SELECT checkout" + "FROM Return" +
                "Where checkout = " + checkout + ";";
        PreparedStatement s2 = this.connection.prepareStatement(view2);
        s2.execute();
        List<Integer> res2 = new ArrayList<Integer>();
        ResultSet result2 = s2.executeQuery();
        while (result2.next()) {
          res2.add(result2.getInt(1));
        }
        if (res2.size() == 0) {
          String view3 = "CREATE VIEW check3 AS" + "SELECT id" + "FROM LibraryCatalogue" +
                  "Where holding = " + checkout + "and copies_available < num_holdings" + ";";
          PreparedStatement s3 = this.connection.prepareStatement(view3);
          s3.execute();
          List<Integer> res3 = new ArrayList<Integer>();
          ResultSet result3 = s3.executeQuery();
          while (result3.next()) {
            res3.add(result3.getInt(1));
          }
          if (res3.size() != 0){
            String view4 = "INSERT INTO RETURN" + "(" + checkout +", NOW());";
            PreparedStatement s4 = this.connection.prepareStatement(view4);
            s4.execute();

            String view5 = "UPDATE LibraryCatalogue" + "SET copies_available = copies_available + 1" +
                    "where holding = "+ checkout + ";";
            PreparedStatement s5 = this.connection.prepareStatement(view5);
            s5.execute();

            String view6 = "SELECT " + "SET copies_available = copies_available + 1" +
                    "where holding = "+ checkout + ";";
            PreparedStatement s6 = this.connection.prepareStatement(view6);
            s5.execute();

            String view7 = "SELECT EXTRACT(DAY FROM CURRENT_DATE - checkout_time) FROM Checkout WHERE id =" +
                    checkout + ";";
            PreparedStatement s7 = this.connection.prepareStatement(view7);
            s7.execute();
            List<Integer> res7 = new ArrayList<Integer>();
            ResultSet result7 = s7.executeQuery();
            while (result7.next()) {
              res7.add(result7.getInt(1));
            }

            String view8 = "SELECT htype FROM Checkout JOIN Holding WHERE Checkout.id = Holding.id and Checkout.id = "
                    + checkout + ";";
            PreparedStatement s8 = this.connection.prepareStatement(view8);
            s8.execute();
            List<String> res8 = new ArrayList<String>();
            ResultSet result8 = s7.executeQuery();
            while (result8.next()) {
              res8.add(result8.getString(1));
            }
            if(res8.get(0).equals("books") || res8.get(0).equals("audiobooks")){ return 0.50 * res7.get(0);}
            else{return 1.00 * res7.get(0);}

          }

        }

      }
      return -1;
    }





  public static void main(String[] args) {

    Assignment2 a2;
    try {
      // Demo of using an ArrayList.
      ArrayList<String> baking = new ArrayList<String>();
      baking.add("croissant");
      baking.add("choux pastry");
      baking.add("jelly roll");

      // Make an instance of the Assignment2 class.  It has an instance 
      // variable that will hold on to our database connection as long
      // as the instance exists -- even between method calls.
      a2 = new Assignment2();

      // Use your connect method to connect to your database.  You need
      // to pass in the url, username, and password, rather than have them
      // hard-coded in the method.  (This is different from the JDBC code
      // we worked on in a class exercise.) Replace the XXXXs with your
      // username, of course.
      a2.connectDB("jdbc:postgresql://localhost:5432/csc343h-XXXX", "XXXX", "");

      // You can call your methods here to test them. It will not affect our 
      // autotester.
      System.out.println("Boo!");
    }
    catch (Exception ex) {      
      System.out.println("exception was thrown");
      ex.printStackTrace();
    }
  }

}

